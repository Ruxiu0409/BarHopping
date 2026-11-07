# BarHopping

串酒吧步行路線規劃 App。規格在 `docs/specs/`，實作前先讀 `00-product-and-contract.md`，契約以規格為準。

## Git 工作流程（必須遵守）

每完成一項工作（一個功能、一次修正、一份文件）就照以下步驟做：

1. **Commit**：只 add 這次相關的檔案，寫清楚的 commit message。
2. **檢查 GitHub**：執行 `git fetch`，再用 `git log --oneline HEAD..origin/<目前分支>` 看遠端有沒有新 commit。
3. **有新東西就 pull**：執行 `git pull --rebase`。
   - 有衝突時停下來，把衝突的檔案和內容告訴使用者，不要自己挑一邊覆蓋。
   - pull 下來的內容如果改了規格（`docs/specs/`）或共用模型，先讀過再繼續做。
4. 有 subagent 平行工作時，由主 agent 統一做 commit 和 pull，subagent 不自行 commit。

開始新工作前也先 fetch 一次，確認自己在最新版本上。
