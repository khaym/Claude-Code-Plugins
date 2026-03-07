# License Compatibility Matrix

## Permissive Licenses (compatible with MIT, Apache-2.0, BSD)

| License | Attribution Required | Notice File Required | Compatible with MIT |
|---------|---------------------|---------------------|-------------------|
| MIT | Yes | No | Yes |
| ISC | Yes | No | Yes |
| BSD-2-Clause | Yes | No | Yes |
| BSD-3-Clause | Yes | No | Yes |
| Apache-2.0 | Yes | Yes (if NOTICE exists) | Yes |
| Unlicense | No | No | Yes |
| CC0-1.0 | No | No | Yes |
| 0BSD | No | No | Yes |
| BlueOak-1.0.0 | Yes | No | Yes |

## Copyleft Licenses (require project license change or isolation)

| License | Severity | Impact |
|---------|----------|--------|
| GPL-2.0 | FAIL | Requires entire project to be GPL-2.0 |
| GPL-3.0 | FAIL | Requires entire project to be GPL-3.0 |
| AGPL-3.0 | FAIL | Requires entire project to be AGPL-3.0 (network use) |
| LGPL-2.1 | WARN | OK if dynamically linked; bundling may require LGPL |
| LGPL-3.0 | WARN | OK if dynamically linked; bundling may require LGPL |
| MPL-2.0 | WARN | File-level copyleft; modified MPL files must stay MPL |
| CC-BY-SA-4.0 | WARN | Share-alike requirement for derivative works |

## Attribution Requirements by License

When a dependency uses one of these licenses, the project should include attribution:

- **Apache-2.0**: Must reproduce LICENSE and NOTICE file contents in THIRD_PARTY_LICENSES
- **MIT / ISC / BSD**: Must reproduce copyright notice and license text
- **CC-BY-4.0**: Must give credit, link to license, indicate changes
