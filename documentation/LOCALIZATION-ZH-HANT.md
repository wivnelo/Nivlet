# 繁體中文在地化用語

本字典以台灣使用者的 macOS 桌面操作情境撰寫。語言識別使用 `zh-Hant`；台灣地區的顯示格式使用 `zh-TW`。若香港或澳門的繁體中文系統語言選用這份字典，顯示的是台灣用語，並不代表另有香港或澳門在地化版本。

以下詞彙以 Apple 台灣介面為參考，並依 Nivlet 的功能語境統一。不是將簡體字逐字轉換為繁體字。

| 概念 | 採用用語 | 使用方式 |
| --- | --- | --- |
| Save / settings | 儲存／設定 | 「儲存所有設定」、「取消此頁變更」；儲存與放棄變更須清楚區分。 |
| General / menu bar / window | 一般／選單列／視窗 | 與 macOS 設定及視窗操作用語一致。 |
| Shortcut / modifier | 快速鍵／變更鍵 | 保留 Control、Option、Command、Return 與按鍵符號。 |
| Clipboard / copy / paste | 剪貼板／拷貝／貼上 | 使用 Apple 台灣的剪貼板操作用語；不將「拷貝內容」誤寫成複製檔案。 |
| Accessibility | 輔助使用 | 引導至「系統設定」→「隱私權與安全性」→「輔助使用」。 |
| App / input source | App／輸入方式 | 「依 App 切換輸入方式」；系統提供的 App 與輸入方式名稱原樣顯示。 |
| Domain / port | 網域／連接埠 | 「網域規則」、「包含子網域」；URL 與 punycode 原樣保留。 |
| Match / fallback browser | 比對／未符合規則時使用 | 清楚說明規則順序，不把 fallback 誤譯成備援故障切換。 |
| Local / cache | 本機／快取 | 「本機未加密快取」直接表達原有儲存方式。 |
| Memory / disk | 記憶體／磁碟 | 系統資訊的標籤保持一致。 |
| Configuration import / export | 匯入設定／匯出設定 | 不改設定檔格式、Bundle ID 或 JSON 欄位名稱。 |
| Discard / restore | 放棄變更／還原 | 取消頁面編輯與不可復原的清除記錄使用不同文案。 |

完整字典位於 `Toolkit/modules/translations_zh_hant.lua`。來源鍵保留原有簡體中文以維持相容；語言選項的自稱 `简体中文`、`English`、`繁體中文`、`日本語` 保留原文。品牌、Bundle ID、URL、檔案副檔名、數值範圍及快速鍵語法皆不翻譯。

覆蓋檢查包含現有英文辭典的全部來源鍵、Lua `i18n.t(...)`、JavaScript `t(...)`、設定 HTML 的靜態文字及可翻譯屬性。另補入原字典遺漏的匯入預覽說明。歷史上已不再顯示的文案仍保留對應鍵，不藉翻譯更改產品行為。

撰寫與獨立語言複核由 AI 執行，尚未經台灣母語使用者人工校對。最終八頁畫面、錯誤狀態、深淺色及窄視窗的驗證由本次整合驗收記錄列出；此用語表本身不代表實機驗收已通過。

參考：Apple 台灣的 [Mac 鍵盤快速鍵](https://support.apple.com/zh-tw/102650)（快速鍵、變更鍵、剪貼板、拷貝、貼上、輔助使用）及 [更改「外觀」設定](https://support.apple.com/zh-tw/guide/mac-help/mchlp1225/mac)（設定、選單列、視窗、淺色與深色）。
