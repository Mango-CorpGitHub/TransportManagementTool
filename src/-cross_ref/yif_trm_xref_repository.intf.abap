INTERFACE yif_trm_xref_repository
  PUBLIC.

  TYPES ty_t_objects    TYPE STANDARD TABLE OF cnvcdmccts_objects_set WITH DEFAULT KEY.
  TYPES ty_t_references TYPE STANDARD TABLE OF cnvcdmccts_objs_ref WITH DEFAULT KEY.

  "! Fragments (sub-objects) and non versionable objects of the given objects
  METHODS get_fragments
    IMPORTING it_objects          TYPE ty_t_objects
    RETURNING VALUE(rt_fragments) TYPE ty_t_objects
    RAISING   ycx_trm_cross_reference.

  "! Objects used by the given objects
  METHODS get_references
    IMPORTING it_objects           TYPE ty_t_objects
    RETURNING VALUE(rt_references) TYPE ty_t_references.

  "! Methods with the class part where they are defined informed in PGMID
  METHODS resolve_methods
    IMPORTING it_methods        TYPE ty_t_objects
    RETURNING VALUE(rt_methods) TYPE ty_t_objects.

  "! Methods and redefinitions of a class part (CPUB, CPRO, CPRI)
  METHODS get_class_part_methods
    IMPORTING iv_part           TYPE trobjtype
              iv_class_name     TYPE trobj_name
    RETURNING VALUE(rt_methods) TYPE string_table.

  METHODS has_own_pgmid
    IMPORTING iv_object_type   TYPE trobjtype
    RETURNING VALUE(rv_result) TYPE abap_bool.

  "! Reference converted to the notation used to compare with the destination system
  METHODS normalize_reference
    IMPORTING is_reference         TYPE cnvcdmccts_objs_ref
    RETURNING VALUE(rt_normalized) TYPE ty_t_references.

  METHODS is_sap_object
    IMPORTING is_object        TYPE cnvcdmccts_objects_set
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS method_exists
    IMPORTING iv_class_name    TYPE tmdir-classname
              iv_method_name   TYPE tmdir-methodname
    RETURNING VALUE(rv_result) TYPE abap_bool.

ENDINTERFACE.
