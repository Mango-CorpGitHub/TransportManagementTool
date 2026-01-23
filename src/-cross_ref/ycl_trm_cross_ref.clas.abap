CLASS ycl_trm_cross_ref DEFINITION
  PUBLIC
  CREATE PROTECTED
  GLOBAL FRIENDS ycl_trm_cross_ref_analisys.

  PUBLIC SECTION.
    INTERFACES yif_trm_cross_reference.

  PROTECTED SECTION.
    CLASS-METHODS create
      IMPORTING is_data                   TYPE yif_trm_cross_reference=>ty_s_result
      RETURNING VALUE(ro_cross_reference) TYPE REF TO yif_trm_cross_reference.

    METHODS constructor
      IMPORTING is_data TYPE yif_trm_cross_reference=>ty_s_result.

    DATA cross_reference_data TYPE yif_trm_cross_reference=>ty_s_result.

ENDCLASS.


CLASS ycl_trm_cross_ref IMPLEMENTATION.
  METHOD create.
    CASE is_data-reference_fragment.
      WHEN 'METH'.
        RETURN NEW ycl_trm_cross_reference_meth( is_data ).

      WHEN 'TABD'.
        RETURN NEW ycl_trm_cross_reference_tabd( is_data ).

      WHEN 'DDLS'.
        RETURN NEW ycl_trm_cross_reference_ddls( is_data ).

      WHEN 'CLAS' OR 'INTF'.
        RETURN NEW ycl_trm_cross_reference_obj( is_data ).

      WHEN 'CPUB' OR 'CPRO' OR 'CPRI'.
        RETURN NEW ycl_trm_cross_ref_obj_part( is_data ).

      WHEN OTHERS.
        RETURN NEW ycl_trm_cross_ref( is_data ).

    ENDCASE.
  ENDMETHOD.

  METHOD constructor.
    cross_reference_data = is_data.
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
