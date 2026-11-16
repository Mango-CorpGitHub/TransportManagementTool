INTERFACE yif_trm_xref_system
  PUBLIC.

  TYPES: BEGIN OF ty_s_object,
           object_pgmid TYPE pgmid,
           object_type  TYPE trobjtype,
           object_name  TYPE trobj_name,
         END OF ty_s_object.

  TYPES: BEGIN OF ty_s_method_description,
           defined_in TYPE ty_s_object,
           exceptions TYPE STANDARD TABLE OF vseoexcep WITH DEFAULT KEY,
           parameters TYPE STANDARD TABLE OF vseoparam WITH DEFAULT KEY,
         END OF ty_s_method_description.

  TYPES: BEGIN OF ty_s_table_description,
           fields TYPE STANDARD TABLE OF dd03v WITH DEFAULT KEY,
         END OF ty_s_table_description.

  TYPES: BEGIN OF ty_s_cds_description,
           fields TYPE ytrm_t_ddl_base_fields,
         END OF ty_s_cds_description.

  TYPES: BEGIN OF ty_s_description,
           object_pgmid          TYPE pgmid,
           object_type           TYPE trobjtype,
           object_name           TYPE trobj_name,
           sub_object_type       TYPE trobjtype,
           sub_object_name       TYPE trobj_name,
           sub_object_name_alias TYPE trobj_name,
           method_description    TYPE ty_s_method_description,
           source_code           TYPE string,
         END OF ty_s_description.
  TYPES ty_t_description TYPE STANDARD TABLE OF ty_s_description WITH DEFAULT KEY.

  "! Components of a class (including inherited ones) or interface
  METHODS describe
    IMPORTING iv_object_name        TYPE vrsd-objname
    RETURNING VALUE(rt_description) TYPE ty_t_description
    RAISING   ycx_trm_cross_reference.

  METHODS describe_method
    IMPORTING iv_object_name        TYPE string
              iv_method_name        TYPE string
    RETURNING VALUE(rs_description) TYPE ty_s_method_description
    RAISING   ycx_trm_cross_reference.

  "! Components of a class part (CPUB, CPRO, CPRI)
  METHODS describe_class_part
    IMPORTING iv_part               TYPE trobjtype
              iv_object_name        TYPE vrsd-objname
    RETURNING VALUE(rt_description) TYPE ty_t_description
    RAISING   ycx_trm_cross_reference.

  METHODS describe_table
    IMPORTING iv_table_name         TYPE vrsd-objname
    RETURNING VALUE(rs_description) TYPE ty_s_table_description
    RAISING   ycx_trm_cross_reference.

  METHODS describe_cds
    IMPORTING iv_cds_name           TYPE vrsd-objname
    RETURNING VALUE(rs_description) TYPE ty_s_cds_description
    RAISING   ycx_trm_cross_reference.

  "! Compares the active version of the objects in the local system with this system
  METHODS compare_versions
    IMPORTING it_objects           TYPE scwb_t_e071
    RETURNING VALUE(rt_comparison) TYPE vrs_compare_item_tab
    RAISING   ycx_trm_cross_reference.

  METHODS object_exists
    IMPORTING iv_pgmid         TYPE pgmid
              iv_object        TYPE trobjtype
              iv_obj_name      TYPE trobj_name
    RETURNING VALUE(rv_result) TYPE abap_bool.

ENDINTERFACE.
