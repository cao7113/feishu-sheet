# FeishuSheet - Access Feishu Sheets Data

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `feishu_sheet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:feishu_sheet, "~> 0.1.0"}
  ]
end
```

set environment varibles

```
export FEISHU_APP_ID="xxx"
export FEISHU_APP_SECRET="xxx"
```

## Usage

`FeishuSheet.get_sheet_data!("xxx_spreedsheet_oken", 0, "A1", "C")`

## Terms

- spreadsheet, table are same, maybe contain multiple worksheets, specified by spreadsheet_token
- sheet is short for worksheet, specified by sheet_id

## Acess Token

- https://open.feishu.cn/document/faq/trouble-shooting/how-to-choose-which-type-of-token-to-use
- https://open.feishu.cn/document/server-docs/api-call-guide/calling-process/get-access-token

## Error Code

- https://open.feishu.cn/document/server-docs/api-call-guide/generic-error-code
