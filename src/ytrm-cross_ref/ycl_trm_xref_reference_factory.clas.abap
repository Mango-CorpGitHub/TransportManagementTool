CLASS ycl_trm_xref_reference_factory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_source_system      TYPE REF TO yif_trm_xref_system
                io_destination_system TYPE REF TO yif_trm_xref_system.

    "! Reference with the behaviour of the type of the referenced object
    METHODS create
      IMPORTING is_data             TYPE yif_trm_cross_reference=>ty_s_result
      RETURNING VALUE(ro_reference) TYPE REF TO yif_trm_cross_reference.

  PRIVATE SECTION.
    DATA ai_o_source_system      TYPE REF TO yif_trm_xref_system.
    DATA ai_o_destination_system TYPE REF TO yif_trm_xref_system.

ENDCLASS.


CLASS ycl_trm_xref_reference_factory IMPLEMENTATION.

  METHOD constructor.
    ai_o_source_system      = io_source_system.
    ai_o_destination_system = io_destination_system.
  ENDMETHOD.

  METHOD create.
    CASE is_data-reference_fragment.
      WHEN 'METH'.
        RETURN NEW ycl_trm_cross_reference_meth( is_data               = is_data
                                                 io_source_system      = ai_o_source_system
                                                 io_destination_system = ai_o_destination_system ).

      WHEN 'TABD'.
        RETURN NEW ycl_trm_cross_reference_tabd( is_data               = is_data
                                                 io_source_system      = ai_o_source_system
                                                 io_destination_system = ai_o_destination_system ).

      WHEN 'DDLS'.
        RETURN NEW ycl_trm_cross_reference_ddls( is_data               = is_data
                                                 io_source_system      = ai_o_source_system
                                                 io_destination_system = ai_o_destination_system ).

      WHEN 'CLAS' OR 'INTF'.
        RETURN NEW ycl_trm_cross_reference_obj( is_data               = is_data
                                                io_source_system      = ai_o_source_system
                                                io_destination_system = ai_o_destination_system ).

      WHEN 'CPUB' OR 'CPRO' OR 'CPRI'.
        RETURN NEW ycl_trm_cross_ref_obj_part( is_data               = is_data
                                               io_source_system      = ai_o_source_system
                                               io_destination_system = ai_o_destination_system ).

      WHEN OTHERS.
        RETURN NEW ycl_trm_cross_ref( is_data               = is_data
                                      io_source_system      = ai_o_source_system
                                      io_destination_system = ai_o_destination_system ).

    ENDCASE.
  ENDMETHOD.

ENDCLASS.
