CLASS ycl_trm_get_objects_w_colision DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .


  PUBLIC SECTION.

    TYPES:
      ty_r_transport_request TYPE RANGE OF string .
    TYPES:
      BEGIN OF ty_s_objects,
        pgmid    TYPE string,
        object   TYPE string,
        obj_name TYPE string,
      END OF ty_s_objects .
    TYPES:
      tyt_objects TYPE STANDARD TABLE OF ty_s_objects WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_s_colisions,
        request  TYPE string,
        pgmid    TYPE string,
        object   TYPE string,
        obj_name TYPE string,
      END OF ty_s_colisions .
    TYPES:
      tyt_colisions TYPE STANDARD TABLE OF ty_s_colisions WITH DEFAULT KEY .

    CLASS-METHODS create
      RETURNING
        VALUE(ro_as) TYPE REF TO ycl_trm_get_objects_w_colision .
    METHODS find
      IMPORTING
        !it_objects_being_transported TYPE tyt_objects
        !ir_tr_being_transported      TYPE ty_r_transport_request
      RETURNING
        VALUE(rt_colisions)           TYPE tyt_colisions .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES _ty_r_transport_request TYPE RANGE OF v_e071eu-trkorr.
    TYPES _ty_r_parent_request TYPE RANGE OF v_e071eu-strkorr.
    TYPES _ty_t_v_e071eu TYPE STANDARD TABLE OF v_e071eu WITH DEFAULT KEY.

ENDCLASS.



CLASS ycl_trm_get_objects_w_colision IMPLEMENTATION.


  METHOD create.
    ro_as = NEW ycl_trm_get_objects_w_colision( ).
  ENDMETHOD.


  METHOD find.

    IF lines( it_objects_being_transported ) = 0.
      RETURN.
    ENDIF.

    DATA(lr_transport_request) = CORRESPONDING _ty_r_transport_request( ir_tr_being_transported ).
    DATA(lr_parent_request) = CORRESPONDING _ty_r_parent_request( ir_tr_being_transported ).
    DATA(lt_objects_being_transported) = CORRESPONDING _ty_t_v_e071eu( it_objects_being_transported ).

*   Find if it is in other TR:
    SELECT * FROM v_e071eu
       FOR ALL ENTRIES IN @lt_objects_being_transported
       WHERE obj_name = @lt_objects_being_transported-obj_name AND
             object   = @lt_objects_being_transported-object AND
             ( trstatus NE 'R' AND trstatus NE 'N' )
       INTO TABLE @DATA(lt_colisions).
    IF lines( lt_colisions ) = 0 .
      RETURN.
    ENDIF.

*   delete the same order
    DELETE lt_colisions WHERE trkorr IN lr_transport_request OR strkorr IN lr_parent_request.

*   delete the entry in tables
    DELETE lt_colisions WHERE object = 'TABU' AND ( obj_name = 'TDDAT' OR obj_name = 'TVDIR' ).

* Delete the entries that doesn't have to be considered
    DELETE lt_colisions WHERE pgmid = 'R3TR' AND ( object = 'TABU' OR object = 'VDAT' OR object = 'TDAT' ).

* Delete duplicates
    rt_colisions = VALUE #( FOR ls_colision IN lt_colisions
    ( request   = COND #( WHEN ls_colision-strkorr IS NOT INITIAL THEN ls_colision-strkorr ELSE ls_colision-trkorr )
      pgmid     = ls_colision-pgmid
      object    = ls_colision-object
      obj_name  = ls_colision-obj_name ) ).

    SORT rt_colisions BY request pgmid object obj_name.
    DELETE ADJACENT DUPLICATES FROM rt_colisions.

*    IF lines( ir_transport_requests ) = 0.
*      RETURN.
*    ENDIF.
*
*    DATA(lr_transport_request) = CORRESPONDING _ty_r_transport_request( ir_transport_requests ).
*    DATA(lr_parent_request) = CORRESPONDING _ty_r_parent_request( ir_transport_requests ).
*
*    SELECT * FROM v_e071eu
*      WHERE trkorr IN @lr_transport_request
*        OR strkorr IN @lr_parent_request
*      INTO TABLE @DATA(lt_objects).
*
**   Busquem si està en alguna altre ordre:
*    SELECT * FROM v_e071eu
*       FOR ALL ENTRIES IN @lt_objects
*       WHERE obj_name = @lt_objects-obj_name AND
*             object   = @lt_objects-object AND
*             ( trstatus NE 'R' AND trstatus NE 'N' )
*       INTO TABLE @rt_colisions.
*    IF lines( rt_colisions ) = 0 .
*      RETURN.
*    ENDIF.
*
**   delete the same order
*    DELETE rt_colisions WHERE trkorr IN ir_transport_requests OR
*                              strkorr IN ir_transport_requests.
*
**   delete the entry in tables
*    DELETE rt_colisions WHERE object = 'TABU' AND ( obj_name = 'TDDAT' OR obj_name = 'TVDIR' ).
*
** Delete the entries that doesn't have to be considered
*    DELETE rt_colisions WHERE pgmid = 'R3TR' AND ( object = 'TABU' OR object = 'VDAT' OR object = 'TDAT' ).

  ENDMETHOD.
ENDCLASS.
