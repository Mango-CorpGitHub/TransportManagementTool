CLASS ycl_trm_cross_reference_meth DEFINITION
  PUBLIC
  INHERITING FROM ycl_trm_cross_ref FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS ycl_trm_xref_reference_factory.

  PUBLIC SECTION.
    METHODS yif_trm_cross_reference~compare  REDEFINITION.
    METHODS yif_trm_cross_reference~exists   REDEFINITION.
    METHODS yif_trm_cross_reference~navigate REDEFINITION.

    ALIASES compare  FOR yif_trm_cross_reference~compare.
    ALIASES exists   FOR yif_trm_cross_reference~exists.
    ALIASES navigate FOR yif_trm_cross_reference~navigate.

    METHODS describe
      IMPORTING iv_in_destination            TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rs_method_description) TYPE yif_trm_xref_system=>ty_s_method_description
      RAISING   ycx_trm_cross_reference.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_s_method,
             clas_or_intf TYPE string,
             method       TYPE string,
           END OF ty_s_method.

    "! Alias used by the reference, if the method was referenced through an alias
    DATA alias_name TYPE string.

    METHODS split
      IMPORTING iv_fragname      TYPE trobj_name
      RETURNING VALUE(rs_method) TYPE ty_s_method.

    "! A mandatory parameter is always passed by the callers
    METHODS is_mandatory
      IMPORTING is_parameter     TYPE vseoparam
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS alias_exists_in_destination
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS constructor
      IMPORTING is_data               TYPE yif_trm_cross_reference=>ty_s_result
                io_source_system      TYPE REF TO yif_trm_xref_system
                io_destination_system TYPE REF TO yif_trm_xref_system.

ENDCLASS.


CLASS ycl_trm_cross_reference_meth IMPLEMENTATION.

  METHOD constructor.
    super->constructor( is_data               = is_data
                        io_source_system      = io_source_system
                        io_destination_system = io_destination_system ).

    " Cambiar el nombre del método si es un alias
    TRY.
        FINAL(lt_class_description) = source_system->describe(
                                          CONV #( cross_reference_data-reference_fragname(30) ) ).
      CATCH ycx_trm_cross_reference.
        RETURN.
    ENDTRY.

    FINAL(lv_method_name) = cross_reference_data-reference_fragname+30.
    FINAL(lv_method_name_if_alias) = VALUE #( lt_class_description[
                                                  sub_object_name_alias = lv_method_name ]-sub_object_name OPTIONAL ).
    IF lv_method_name_if_alias IS INITIAL.
      RETURN.
    ENDIF.

    cross_reference_data-reference_fragname+30 = lv_method_name_if_alias.
    alias_name = lv_method_name.

    " Genera error si el nombre del metodo tambien esta en la clase: ZCL_FI_ADI_NOMINAS_MAPPER_MX  MAPP = ZCL_FI_ADI_NOMINAS_ZIF_FI_ADI_FILE_MAPPER~MAPPER_MX  MAPP
*    REPLACE lv_method_name IN cross_reference_data-reference_fragname WITH lv_method_name_if_alias.

  ENDMETHOD.

  METHOD yif_trm_cross_reference~compare.
    TRY.
        FINAL(lt_current_system_param) = describe( )-parameters.
      CATCH ycx_trm_cross_reference.
    ENDTRY.

    TRY.
        FINAL(lt_destination_system_param) = describe( iv_in_destination = abap_true )-parameters.
      CATCH ycx_trm_cross_reference.
    ENDTRY.

    rt_comparison = VALUE #( FOR ls_current_system_param IN lt_current_system_param
                             ( status   = yif_trm_cross_reference=>c_status-only_in_source
                               severity = COND #( WHEN is_mandatory( ls_current_system_param )
                                                  THEN icon_led_red
                                                  ELSE icon_led_yellow )
                               name     = ls_current_system_param-sconame
                               type     = ls_current_system_param-type ) ).

    LOOP AT lt_destination_system_param ASSIGNING FIELD-SYMBOL(<ls_destination_system_param>).

      ASSIGN rt_comparison[ name = <ls_destination_system_param>-sconame ] TO FIELD-SYMBOL(<ls_comparison>) ELSE UNASSIGN.
      IF <ls_comparison> IS ASSIGNED.

        IF <ls_comparison>-type = <ls_destination_system_param>-type.
          <ls_comparison>-status   = yif_trm_cross_reference=>c_status-equal_in_destination.
          <ls_comparison>-severity = icon_led_green.
          CONTINUE.
        ENDIF.

        <ls_comparison>-status   = yif_trm_cross_reference=>c_status-different_in_destination.
        <ls_comparison>-severity = icon_led_yellow.
        CONTINUE.

      ENDIF.

      " No existe en origen
      " Si en destino hay un parámetro obligatorio que no está en origen, va a dar error
      INSERT VALUE yif_trm_cross_reference=>ty_s_comparison(
          severity = COND #( WHEN <ls_destination_system_param>-paroptionl = abap_true OR <ls_destination_system_param>-parpreferd = abap_true OR <ls_destination_system_param>-parvalue IS NOT INITIAL
                             THEN icon_led_green
                             ELSE icon_led_red )
          status   = yif_trm_cross_reference=>c_status-only_in_destination
          name     = <ls_destination_system_param>-sconame
          type     = <ls_destination_system_param>-type )
             INTO TABLE rt_comparison.

    ENDLOOP.

  ENDMETHOD.

  METHOD split.
    " Posible formato METH object_name
    " ZIF_FI_ACCOUNTING_DOC_ITEM_D~SET_GLACCOUNT  <-- Referencia de un método de una interface
    " ZCX_FI_ACCOUNTING_DOCUMENT    CONSTRUCTOR <-- método de una clase
    " ZCL_FI_ACCOUNTING_DOC_ITEM_D  ZIF_FI_ACCOUNTING_DOC_ITEM_D~SET_AMOUNTINCOMPNYCODECURRENCY <-- método de una clase definido en interfaz

    SPLIT iv_fragname AT '~' INTO TABLE FINAL(lt_splitted).
    IF lines( lt_splitted ) = 1.
      " ZCX_FI_ACCOUNTING_DOCUMENT    CONSTRUCTOR <-- método de una clase
      rs_method-clas_or_intf = iv_fragname(30).
      rs_method-method       = iv_fragname+30.
      RETURN.
    ENDIF.

    " ZIF_FI_ACCOUNTING_DOC_ITEM_D~SET_GLACCOUNT  <-- Referencia de un método de una interface
    " ZCL_FI_ACCOUNTING_DOC_ITEM_D  ZIF_FI_ACCOUNTING_DOC_ITEM_D~SET_AMOUNTINCOMPNYCODECURRENCY <-- método de una clase definido en interfaz
    rs_method-method       = lt_splitted[ 2 ].
    rs_method-clas_or_intf = lt_splitted[ 1 ].
    TRY.
        rs_method-clas_or_intf = rs_method-clas_or_intf+30.
      CATCH cx_sy_range_out_of_bounds.
        rs_method-clas_or_intf = lt_splitted[ 1 ].
    ENDTRY.
  ENDMETHOD.

  METHOD describe.
    FINAL(ls_method_splitted) = split( cross_reference_data-reference_fragname ).

    RETURN system( iv_in_destination )->describe_method( iv_object_name = ls_method_splitted-clas_or_intf
                                                         iv_method_name = ls_method_splitted-method ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~exists.
    TRY.
        describe( iv_in_destination = abap_true ).
      CATCH ycx_trm_cross_reference.
        RETURN abap_false.
    ENDTRY.

    " Callers use the alias: it has to exist in the destination too
    RETURN xsdbool( alias_name IS INITIAL OR alias_exists_in_destination( ) ).
  ENDMETHOD.

  METHOD alias_exists_in_destination.
    TRY.
        FINAL(lt_class_description) = destination_system->describe(
                                          CONV #( cross_reference_data-reference_fragname(30) ) ).
      CATCH ycx_trm_cross_reference.
        RETURN abap_false.
    ENDTRY.

    rv_result = xsdbool( line_exists( lt_class_description[ sub_object_type       = 'METH'
                                                             sub_object_name_alias = alias_name ] ) ).
  ENDMETHOD.

  METHOD is_mandatory.
    rv_result = xsdbool(     is_parameter-pardecltyp <> '1'   " Exporting
                         AND is_parameter-pardecltyp <> '3'   " Returning
                         AND is_parameter-paroptionl  = abap_false
                         AND is_parameter-parpreferd  = abap_false
                         AND is_parameter-parvalue   IS INITIAL ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~navigate.
    TRY.
        super->yif_trm_cross_reference~navigate( ).
      CATCH ycx_trm_transport_request.

        FINAL(ls_split) = split( cross_reference_data-reference_fragname ).
        ycl_trm_tr_object=>navigate( iv_pgmid       = 'R3TR'
                                     iv_object      = 'INTF'
                                     iv_object_name = CONV #( ls_split-clas_or_intf ) ).

    ENDTRY.
  ENDMETHOD.

ENDCLASS.
