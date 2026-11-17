INTERFACE yif_trm_xref_repository
  PUBLIC.

  TYPES ty_t_objects    TYPE STANDARD TABLE OF cnvcdmccts_objects_set WITH DEFAULT KEY.
  TYPES ty_t_references TYPE STANDARD TABLE OF cnvcdmccts_objs_ref WITH DEFAULT KEY.

  "! Type of the references to components (fields, associations) used of tables, structures and
  "! CDS: <entity>~<component>. It is not a real object type
  CONSTANTS c_used_component TYPE trobjtype VALUE 'XFLD'.

  "! Fragments (sub-objects) and non versionable objects of the given objects
  METHODS get_fragments
    IMPORTING it_objects          TYPE ty_t_objects
    RETURNING VALUE(rt_fragments) TYPE ty_t_objects
    RAISING   ycx_trm_cross_reference.

  "! Components (fields, associations) of tables, structures and CDS used by the given objects,
  "! from the navigation index: type c_used_component, name <entity>~<component>
  METHODS get_used_components
    IMPORTING it_objects           TYPE ty_t_objects
    RETURNING VALUE(rt_references) TYPE ty_t_references.

  "! The CDS has parameters in the local system
  METHODS has_cds_parameters
    IMPORTING iv_cds_name      TYPE trobj_name
    RETURNING VALUE(rv_result) TYPE abap_bool.

  "! Objects used by the given objects
  METHODS get_references
    IMPORTING it_objects           TYPE ty_t_objects
    RETURNING VALUE(rt_references) TYPE ty_t_references.

  "! Methods with the class part where they are defined informed in PGMID
  METHODS resolve_methods
    IMPORTING it_methods        TYPE ty_t_objects
    RETURNING VALUE(rt_methods) TYPE ty_t_objects.

  "! Implemented methods and redefinitions of a class part (CPUB, CPRO, CPRI); interface methods as interface~method
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

  "! Method without implementation (abstract): own method or interface method declared abstract
  "! @parameter iv_method_name | LIMU METH name: class (30) + method or interface~method
  METHODS is_abstract_method
    IMPORTING iv_method_name   TYPE trobj_name
    RETURNING VALUE(rv_result) TYPE abap_bool.

ENDINTERFACE.
