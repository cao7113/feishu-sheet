defmodule FeishuSheet do
  require Logger

  @host "https://open.feishu.cn"

  ## Docs: Spreadsheet

  @doc """
  Get worksheet data by sheet-index(0-based), raise exception when error occured.
  """
  def get_sheet_data!(spreedsheet_token, sheet_index, from_cell, to_cell_or_column, opts \\ []) do
    with {:ok, data} <-
           get_sheet_data(spreedsheet_token, sheet_index, from_cell, to_cell_or_column, opts) do
      data
    else
      err ->
        raise "get sheet data failed #{err |> inspect}"
    end
  end

  @doc """
  Get sheet data by sheet-index(0-based)

  args:
  - sheet_index, 0 based sheet index in the whole spreedsheet
  - from_cell, start cell, e.g. "A1"
  - to_cell_or_column, e.g. "C3", "C"
  """
  def get_sheet_data(spreedsheet_token, sheet_index, from_cell, to_cell_or_column, opts \\ [])
      when is_integer(sheet_index) and is_binary(from_cell) and is_binary(to_cell_or_column) do
    with {:ok,
          %{
            status: 200,
            body: %{
              "code" => 0,
              "data" => %{
                "sheets" => sheets
              }
            }
          }} <- get_sheets_info(spreedsheet_token, opts),
         %{
           "index" => ^sheet_index,
           "resource_type" => "sheet",
           "sheet_id" => sheet_id,
           "title" => _sheet_title
         } <-
           Enum.at(sheets, sheet_index),
         range <- "#{sheet_id}!#{from_cell}:#{to_cell_or_column}",
         {:ok,
          %{
            status: 200,
            body: %{
              "code" => 0,
              "data" => %{
                # "revision" => 26,
                # "spreadsheetToken" => "Ptbds1eKzhFCcwtgMZZc6U8nnNh",
                "valueRange" => %{
                  # "majorDimension" => "ROWS",
                  "range" => _range,
                  # "revision" => 26,
                  "values" => values
                }
              }
              # "msg" => "success"
            }
          }} <- get_sheet_values(spreedsheet_token, range, opts) do
      if opts[:raw_data] do
        {:ok, values}
      else
        {:ok, parse_rows_data(values, opts)}
      end
    end
  end

  @doc """
  Parse rows data as map with headers.

  Options:

    :headers – When set to true, will take the first row of the csv and use it as header values. When set to a list, will use the given list as header values. When set to false (default), will use no header values. When set to anything but false, the resulting rows in the matrix will be maps instead of lists.

  Smaple rows:
    [
      ["name", "job", nil, nil, nil],
      ["alice", "developer", nil, nil, nil],
      ["bob", "tester", nil, nil, nil]
    ]
  """
  def parse_rows_data(rows, opts \\ [])
  def parse_rows_data([], _opts), do: []

  def parse_rows_data(rows, opts) when is_list(rows) do
    {header, values} = parse_header_and_values(rows, opts)

    values
    |> Enum.map(fn row ->
      header
      |> Enum.zip(row)
      |> Map.new()
    end)
  end

  # Require first row must be the header row when require headers, otherwise genrated default headers.
  def parse_header_and_values([first_row | rest] = rows, opts \\ []) do
    l = length(first_row)

    opts[:headers]
    |> case do
      true ->
        headers =
          first_row
          |> Enum.with_index(fn
            nil, i -> field_name(i + 1)
            f, _ -> f
          end)

        {headers, rest}

      h when is_list(h) ->
        headers =
          if length(h) < l do
            (h ++ (l - length(h))..l) |> Enum.map(&field_name/1)
          else
            h |> Enum.slice(0, l)
          end

        {headers, rest}

      _ ->
        # auto-gen header name, 1-based
        headers = 1..l |> Enum.map(&field_name/1)
        {headers, rows}
    end
  end

  @field_prefix "field"
  def field_name(i) when is_integer(i) do
    @field_prefix <> <<?A + i - 1>>
  end

  # curl --location --request GET 'https://open.feishu.cn/open-apis/sheets/v2/spreadsheets/shtcngNygNfuqhxTBf588jwgWbJ/values/Q7PlXT!A3:D200?valueRenderOption=ToString&dateTimeRenderOption=FormattedString' \
  # --header 'Authorization: Bearer t-ce3540c5f02ac074535f1f14d64fa90fa49621c0'
  def get_sheet_values(spreedsheet_token, range, opts \\ []) do
    "/open-apis/sheets/v2/spreadsheets/#{spreedsheet_token}/values/#{range}?valueRenderOption=ToString&dateTimeRenderOption=FormattedString"
    |> do_get(headers: headers_with_auth(opts))
  end

  # curl -i -X GET 'https://open.feishu.cn/open-apis/sheets/v3/spreadsheets/Ptbds1eKzhFCcwtgMZZc6U8nnNh/sheets/3e5db5' \
  # -H 'Authorization: Bearer u-eoRasKhZh5t9XAX4hcNybe01kiTkggPHOww0g02aw33t'
  # body: %{
  #   "code" => 0,
  #   "data" => %{
  #     "sheets" => [
  #       %{
  #         "grid_properties" => %{
  #           "column_count" => 20,
  #           "frozen_column_count" => 0,
  #           "frozen_row_count" => 1,
  #           "row_count" => 199
  #         },
  #         "hidden" => false,
  #         "index" => 0,
  #         "resource_type" => "sheet",
  #         "sheet_id" => "3e5db5",
  #         "title" => "Sheet1"
  #       }
  #     ]
  #   }
  # }
  def get_sheet_info(spreadsheet_token, sheet_id, opts \\ []) do
    "/open-apis/sheets/v3/spreadsheets/#{spreadsheet_token}/#{sheet_id}"
    |> do_get(headers: headers_with_auth(opts))
  end

  # curl -i -X GET 'https://open.feishu.cn/open-apis/sheets/v3/spreadsheets/Ptbds1eKzhFCcwtgMZZc6U8nnNh/sheets/query' \
  # -H 'Authorization: Bearer u-eoRasKhZh5t9XAX4hcNybe01kiTkggPHOww0g02aw33t'
  def get_sheets_info(spreadsheet_token, opts \\ []) do
    "/open-apis/sheets/v3/spreadsheets/#{spreadsheet_token}/sheets/query"
    |> do_get(headers: headers_with_auth(opts))
  end

  # curl -i -X GET 'https://open.feishu.cn/open-apis/sheets/v3/spreadsheets/Ptbds1eKzhFCcwtgMZZc6U8nnNh' \
  # -H 'Authorization: Bearer u-ckM_gOm9x0FbCTCNWVYyxv01mUlkgghbiMw04h2aw77o'
  def get_metadata_of_spreadsheet(spreadsheet_token, opts \\ []) do
    "/open-apis/sheets/v3/spreadsheets/#{spreadsheet_token}"
    |> do_get(headers: headers_with_auth(opts))
  end

  ## Space

  # https://open.feishu.cn/document/server-docs/docs/drive-v1/folder/get-root-folder-meta
  def get_metadata_of_root_folder(opts \\ []) do
    "/open-apis/drive/explorer/v2/root_folder/meta"
    |> do_get(headers: headers_with_auth(opts))
  end

  ## Client and Auth

  def do_post(path, req_opts \\ []) do
    path
    |> url_for()
    |> Req.post(req_opts)
  end

  def do_get(path, req_opts \\ []) do
    path
    |> url_for()
    |> Req.get(req_opts)
  end

  def get_access_token!(tp \\ :tenant, opts \\ []) do
    tp
    |> case do
      :app ->
        get_app_access_token!(opts)

      :tenant ->
        get_tenant_access_token!(opts)
    end
  end

  # https://open.feishu.cn/document/server-docs/authentication-management/access-token/app_access_token_internal
  def get_app_access_token!(_opts \\ []) do
    # add caching logic when not expired?
    with {:ok, token} <- fetch_app_access_token() do
      token
    else
      err ->
        Logger.error("get_app_access_token failed with #{err |> inspect}")
        raise "get_app_access_token failed, refer log"
    end
  end

  def fetch_app_access_token(_opts \\ []) do
    path = "/open-apis/auth/v3/app_access_token/internal"
    body = load_app_config!()

    with {:ok,
          %{
            status: 200,
            body: %{
              "code" => 0,
              "expire" => _,
              "msg" => "ok",
              "app_access_token" => access_token
            }
          }} <- do_post(path, headers: default_headers(), json: body) do
      {:ok, access_token}
    end
  end

  # https://open.feishu.cn/document/server-docs/authentication-management/access-token/tenant_access_token_internal
  def get_tenant_access_token!(_opts \\ []) do
    # add caching logic when not expired?
    with {:ok, token} <- fetch_tenant_access_token() do
      token
    else
      err ->
        Logger.error("get_tenant_access_token failed with #{err |> inspect}")
        raise "get_tenant_access_token failed, refer log"
    end
  end

  def fetch_tenant_access_token(_opts \\ []) do
    path = "/open-apis/auth/v3/tenant_access_token/internal"
    body = load_app_config!()

    with {:ok,
          %{
            status: 200,
            body: %{
              "code" => 0,
              "expire" => _,
              "msg" => "ok",
              "tenant_access_token" => access_token
            }
          }} <- do_post(path, headers: default_headers(), json: body) do
      {:ok, access_token}
    end
  end

  def default_headers,
    do: [
      {"content-type", "application/json; charset=utf-8"}
    ]

  def headers_with_auth(opts \\ []) do
    default_headers() ++
      auth_headers(get_tenant_access_token!(opts))
  end

  def auth_headers(access_token) do
    [{"authorization", "Bearer #{access_token}"}]
  end

  def url_for(path), do: "#{@host}#{path}"

  def load_app_config! do
    %{
      app_id: System.fetch_env!("FEISHU_APP_ID"),
      app_secret: System.fetch_env!("FEISHU_APP_SECRET")
    }
  end
end
