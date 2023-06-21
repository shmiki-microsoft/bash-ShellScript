#!/bin/bash

# 必要な情報を設定
clientId="<client-id>"
clientSecret="<client-secret>"
tenantId="<tenant-id>"
resource="https://graph.microsoft.com"
endpoint="https://graph.microsoft.com/v1.0/auditLogs/signIns"

# アクセストークンを取得
token=$(curl -s -X POST -d "client_id=$clientId&scope=$resource/.default&client_secret=$clientSecret&grant_type=client_credentials" https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token | jq -r '.access_token')

# ページング処理
while [ "$endpoint" != "null" ]
do
    # API をコールしてログを取得
    response=$(curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$endpoint")

    # レスポンスをファイルに出力
    echo $response | jq . >> $output_file

    # 次のページのエンドポイントを取得
    endpoint=$(echo $response | jq -r '.["@odata.nextLink"]')
done