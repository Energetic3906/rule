## Country.mmdb

只包含 CN。

数据来源：

- gaoyifan/china-operator-ip
- ispip.clang

封装格式：mmdb、mrs

## geosite

仅包含中国大陆（CN）域名。

**数据来源：**
- [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)

**筛选与排序：**
- 使用 Tranco Top 1M 域名列表进行筛选，仅保留主域名在 Top 1M 中的条目，并按排名升序排序。
- 参考 Cloudflare 中国访问量 Top 100 列表，剔除其中的国外域名及 Windows 相关域名（如 `.microsoft.com`、`.windowsupdate.com` 等）。
- 支持手动添加域名/后缀（如 `.cn`、中文顶级域名等），绕过 Top 1M 过滤。

**自定义：**
如有不同想法，欢迎 Fork 本仓库后手动修改过滤规则。

只能用于 DNS 分流，不能用来代理分流。

封装格式：dat、list