FUNCTION ytrm_fm_cross_ref_descr_ddls.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(DDLNAME) TYPE  DDLNAME
*"  TABLES
*"      FIELDS TYPE  YTRM_T_DDL_BASE_FIELDS
*"----------------------------------------------------------------------
  fields[] = CORRESPONDING #( cl_dd_ddl_utilities=>if_dd_ddl_utilities~get_cds_base_fields(
                                  CONV ddlname( to_upper( ddlname ) ) ) ).

ENDFUNCTION.
