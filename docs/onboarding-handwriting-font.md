# 導覽展示手寫字型

來源：[Macintosh Skeletal Filled](https://github.com/npwitk/Macintosh-Skeletal-Filled)，使用靜態版 `fonts/MacintoshSkeletalFilled.otf`，PostScript 名稱為 `MacintoshSkeletalFilled-Regular`。

字型衍生自 Apple 的 Macintosh Skeletal，字形、筆畫與 hello 手寫設計的權利屬於 Apple。來源專案未授予 Apple 智慧財產權授權，僅供個人、非商業、教育用途。本專案只供使用者自己的手機做黑客松展示，不隨產品散布字型。

OTF 已列入根目錄 `.gitignore`，不存入 Git。需自行取得上述靜態 OTF，放在此資料夾並命名為 `MacintoshSkeletalFilled.otf`，建置後才會顯示手寫字。請先閱讀來源的 [LICENSE](https://github.com/npwitk/Macintosh-Skeletal-Filled/blob/main/LICENSE)。

程式只在 Bundle 內找到檔案時註冊。沒有檔案或載入失敗時，英文展示字會使用輕量圓角系統字體；中文仍使用原本的系統字體。
