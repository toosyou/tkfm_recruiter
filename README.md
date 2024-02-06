# 天下布魔招募助手 - Beta測試版
專為天下布魔設計的招募助手，幫助凱薩大人找出 SR 的必得組合。

## 截圖

|          主畫面           |           招募畫面           |
|:-------------------------:|:----------------------------:|
| ![](./figs/main_page.jpg) | ![](./figs/recruit_page.jpg) |

## 特色
* 一鍵分析天下布魔招募標籤，找出 SR 的必得組合
* 資料與 [天下布魔工具箱](https://purindaisuki.github.io/tkfmtools/) 同步更新，隨時取得最新資料
* 開源並永遠免費無廣告

## 使用方法

1. 至 [Releases](https://github.com/toosyou/tkfm_recruiter/releases) 下載最新版本 `apk` 安裝檔，開啟進行安裝
2. 開啟後點擊 `開啟助手泡泡` 以開啟助手泡泡
    * 初次開啟時將要求「通知權限」，及「浮動視窗權限」，請依照指示開啟
3. 在招募頁面點擊助手泡泡，即可看到 SR 的必得組合通知
    * 若無法看到通知，請確認是否已開啟「通知權限」並允許招募助手錄製畫面以便截圖

## 限制

* 目前僅支援 Android 版本
* 目前僅支援繁體中文版本的招募畫面，其餘語言版本將無法使用
* 分析使用截圖有失敗機率，若無法正確判斷標籤，歡迎截圖至 [標籤錯誤回報](https://github.com/toosyou/tkfm_recruiter/issues/1)
* 若出現「領袖」標籤請至 [天下布魔工具箱](https://purindaisuki.github.io/tkfmtools/) 查看詳細標籤組合
* 本助手僅提供參考，實際結果仍需依照遊戲內機率計算


## Contribution

* This project is based on [Flutter](https://flutter.dev/).
* All PRs / issues are welcome and should be written in English.
    * Although the project is mainly for traditional Chinese users, for now, multiple-language support is planned.
* Issues before PRs are recommended to discuss the problem before implementation.

## Roadmap

No specific timeline, but the following features are planned:
* [ ] Multiple-language support
* [ ] Automatically tag selection
* [ ] Faster analysis
* [ ] Unit test