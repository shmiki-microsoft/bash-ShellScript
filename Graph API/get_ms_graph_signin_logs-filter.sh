#!/bin/bash
#必要な情報を設定
clientId="<client-id>"
clientSecret="<client-secret>"
tenantId="<tenant-id>"
resource="https://graph.microsoft.com"

# 範囲の指定 (ISO 8601 形式、UTC)
startTime="2023-01-01T00:00:00Z"
endTime="2023-01-31T23:59:59Z"

# URL エンコード用の関数
urlencode() {
    local old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

# 範囲の指定 (ISO 8601 形式、UTC)
startTime="2023-06-20T00:00:00Z"
endTime="2023-06-29T00:00:00Z"

# エンドポイントURLとフィルター条件を組み合わせ
filter="\$filter=activityDateTime ge $startTime and activityDateTime le $endTime"
encoded_filter=$(urlencode "$filter")
endpoint="https://graph.microsoft.com/v1.0/auditLogs/signIns?$encoded_filter"

# アクセストークンを取得
token=$(curl -s -X POST -d "client_id=$clientId&scope=$resource/.default&client_secret=$clientSecret&grant_type=client_credentials" https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token | jq -r '.access_token')

# 現在の日付を取得してファイル名を設定
current_date=$(date '+%Y%m%d')
output_file="signInslogs_$current_date.log"

# ページング処理
while [ "$endpoint" != "null" ]
do
    # API をコールしてログを取得
    response=$(curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$endpoint")

    # レスポンスをファイルに出力
    echo $response | jq . >> $output_file

    # 次のページのエンドポイントを取得
    endpoint=$(echo $response | jq -r '.["@odata.nextLink"]')

    # トークンの有効期限切れチェック
    if [ "$endpoint" != "null" ]; then
        header=$(curl -I -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$endpoint")
        if [[ $header == *"401 Unauthorized"* ]]; then
            # トークン再取得
            token=$(curl -s -X POST -d "client_id=$clientId&scope=$resource/.default&client_secret=$clientSecret&grant_type=client_credentials" https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token | jq -r '.access_token')
        fi
    fi
done