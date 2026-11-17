CLASS ycl_trm_cross_ref DEFINITION
  PUBLIC
  CREATE PROTECTED
  GLOBAL FRIENDS ycl_trm_xref_reference_factory.

  PUBLIC SECTION.
    INTERFACES yif_trm_cross_reference.

  PROTECTED SECTION.
    METHODS constructor
      IMPORTING is_data               TYPE yif_trm_cross_reference=>ty_s_result
                io_source_system      TYPE REF TO yif_trm_xref_system
                io_destination_system TYPE REF TO yif_trm_xref_system.

    DATA cross_reference_data TYPE yif_trm_cross_reference=>ty_s_result.
    DATA source_system        TYPE REF TO yif_trm_xref_system.
    DATA destination_system   TYPE REF TO yif_trm_xref_system.

    "! Local system, or destination system if iv_in_destination is set
    METHODS system
      IMPORTING iv_in_destination TYPE abap_bool
      RETURNING VALUE(ro_system)  TYPE REF TO yif_trm_xref_system.

ENDCLASS.


CLASS ycl_trm_cross_ref IMPLEMENTATION.
  METHOD constructor.
    cross_reference_data = is_data.
    source_system        = io_source_system.
    destination_system   = io_destination_system.
  ENDMETHOD.

  METHOD system.
    ro_system = COND #( WHEN iv_in_destination = abap_true THEN destination_system ELSE source_system ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~get_data.
    RETURN cross_reference_data.
  ENDMETHOD.

  METHOD yif_trm_cross_reference~compare.
    RAISE EXCEPTION NEW cx_method_not_implemented( ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~exists.
    RAISE EXCEPTION NEW cx_method_not_implemented( ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~navigate.
    ycl_trm_tr_object=>navigate( iv_pgmid       = cross_reference_data-reference_fragid
                                 iv_object      = cross_reference_data-reference_fragment
                                 iv_object_name = cross_reference_data-reference_fragname ).
  ENDMETHOD.

ENDCLASS.
