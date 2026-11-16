CLASS ycl_trm_xref_attribute_descr DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Fields (path, type and value) of static attributes and constants of classes and interfaces
    METHODS run
      IMPORTING it_attributes    TYPE ytrm_t_descr_atrb
      RETURNING VALUE(rt_result) TYPE ytrm_t_descr_atrb_result.

  PRIVATE SECTION.
    METHODS describe
      IMPORTING is_attributes    TYPE ytrm_s_descr_atrb
      RETURNING VALUE(rt_result) TYPE ytrm_t_descr_atrb_result.

    METHODS resolve_and_describe
      IMPORTING ir_data          TYPE REF TO data
                iv_prefix        TYPE string OPTIONAL
      RETURNING VALUE(rt_fields) TYPE ytrm_t_descr_atrb_result.

ENDCLASS.


CLASS ycl_trm_xref_attribute_descr IMPLEMENTATION.

  METHOD run.

    LOOP AT it_attributes INTO DATA(ls_attr).
      INSERT LINES OF describe( ls_attr ) INTO TABLE rt_result.
    ENDLOOP.

  ENDMETHOD.

  METHOD describe.

    " Resolver dinámicamente el nombre completo
    " Funciona con interfaces, clases, function groups, programas...
    " Ej: 'ZIF_BC_BUSINESS_PARTNER=>C_PARTNER_FUNCTION_CODE'
    "     'ZCL_MI_CLASE=>GC_ALGO'
    "     '(ZPROGRAMA)GC_CONSTANTE'

    DATA lr_data TYPE REF TO data.

    FIELD-SYMBOLS <data> TYPE any.

    DATA(lv_definition) = to_upper( |{ is_attributes-object_name }=>{ is_attributes-sub_object_name }| ).
    ASSIGN (lv_definition) TO <data>.
    IF <data> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    GET REFERENCE OF <data> INTO lr_data.
    DATA(lt_fields) = resolve_and_describe( lr_data ).
    LOOP AT lt_fields ASSIGNING FIELD-SYMBOL(<ls_field>).
      <ls_field>-object_name     = is_attributes-object_name.
      <ls_field>-sub_object_name = is_attributes-sub_object_name.
    ENDLOOP.

    RETURN lt_fields.

  ENDMETHOD.

  METHOD resolve_and_describe.

    DATA lr_field TYPE REF TO data.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data_ref( ir_data ).

    CASE lo_type->kind.

      WHEN cl_abap_typedescr=>kind_struct.

        DATA(lo_struct) = CAST cl_abap_structdescr( lo_type ).

        ASSIGN ir_data->* TO FIELD-SYMBOL(<struct>).

        LOOP AT lo_struct->get_components( ) ASSIGNING FIELD-SYMBOL(<comp>).

          DATA(lv_path) = COND string(
            WHEN iv_prefix IS INITIAL
            THEN <comp>-name
            ELSE |{ iv_prefix }-{ <comp>-name }| ).

          ASSIGN COMPONENT <comp>-name OF STRUCTURE <struct>
                 TO FIELD-SYMBOL(<field>).

          GET REFERENCE OF <field> INTO lr_field.

          IF <comp>-type->kind = cl_abap_typedescr=>kind_struct.
            INSERT LINES OF resolve_and_describe( ir_data   = lr_field
                                                  iv_prefix = lv_path ) INTO TABLE rt_fields.
          ELSE.

            INSERT VALUE #( path      = lv_path
                            kind      = <comp>-type->kind
                            type_name = <comp>-type->absolute_name
                            length    = <comp>-type->length
                            decimals  = <comp>-type->decimals
                            value     = |{ <field> }| )
                   INTO TABLE rt_fields.

          ENDIF.

        ENDLOOP.

      " --- Elemento simple ---
      WHEN cl_abap_typedescr=>kind_elem.

        ASSIGN ir_data->* TO FIELD-SYMBOL(<elem>).
        INSERT VALUE #( path      = iv_prefix
                        kind      = lo_type->kind
                        type_name = lo_type->absolute_name
                        length    = lo_type->length
                        decimals  = lo_type->decimals
                        value     = |{ <elem> }| )
               INTO TABLE rt_fields.

      " --- Tabla: describir tipo de línea ---
      WHEN cl_abap_typedescr=>kind_table.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
