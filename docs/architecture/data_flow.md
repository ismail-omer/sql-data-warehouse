# Data Flow

![Data Flow](../images/data_flow.png)

## Source-to-Target Lineage

```
crm_sales_details ──┐
crm_cust_info ───────┼──► Bronze ──► Silver ──┐
crm_prd_info ────────┘                        ├──► fact_sales
                                               ├──► dim_customers
erp_cust_az12 ───────┐                        └──► dim_products
erp_loc_a101 ─────────┼──► Bronze ──► Silver ──┘
erp_px_cat_g1v2 ──────┘
```

Every Gold-layer object can be traced back through Silver to its originating
Bronze table and, ultimately, its source system (CRM or ERP).
