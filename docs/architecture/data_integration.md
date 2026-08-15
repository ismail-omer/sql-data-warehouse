# Data Integration

![Data Integration](../images/data_integration.png)

## Entity RelationshipsA

| CRM Entity | Key | ERP Entity | Key | Join Purpose |
|---|---|---|---|---|
| `crm_cust_info` | `cst_key` | `erp_cust_az12` | `cid` | Adds birthdate |
| `crm_cust_info` | `cst_key` | `erp_loc_a101` | `cid` | Adds country/location |
| `crm_prd_info` | `cat_id` (derived from `prd_key`) | `erp_px_cat_g1v2` | `id` | Adds category/subcategory |
| `crm_sales_details` | `prd_key`, `cst_id` | `crm_prd_info`, `crm_cust_info` | — | Links transactions to product & customer |

These relationships are implemented in the Gold-layer views under
`sql/gold/views/`.
