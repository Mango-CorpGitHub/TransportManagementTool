CLASS ycl_trm_get_obj_w_normal_coll DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .


  PUBLIC SECTION.

    INTERFACES yif_trm_get_obj_w_collisions.

    CLASS-METHODS create
      RETURNING
        VALUE(ro_as) TYPE REF TO yif_trm_get_obj_w_collisions .

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES _ty_r_transport_request TYPE RANGE OF v_e071eu-trkorr.
    TYPES _ty_r_parent_request TYPE RANGE OF v_e071eu-strkorr.
    TYPES _ty_t_v_e071eu TYPE STANDARD TABLE OF v_e071eu WITH DEFAULT KEY.

ENDCLASS.



CLASS YCL_TRM_GET_OBJ_W_NORMAL_COLL IMPLEMENTATION.


  METHOD create.
    ro_as = NEW ycl_trm_get_obj_w_normal_coll( ).
  ENDMETHOD.


  METHOD yif_trm_get_obj_w_collisions~find.

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

  ENDMETHOD.
ENDCLASS.
