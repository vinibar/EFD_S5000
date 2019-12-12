*&---------------------------------------------------------------------*
*&  Include           YHRBR_EFD_S5000_REPORT_CI
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*       CLASS lcl_excel_gen IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_excel_gen implementation.

  method factory.

    field-symbols <structure> type any.

    mv_path = iv_path.
    create object mo_instance.

    read table it_structure assigning <structure> index 1.
    if sy-subrc is initial.
*    loop at it_structure assigning <structure>.

      mo_instance->generate_xls_table(
        exporting
          is_structure = <structure>
          iv_header = abap_true
      ).

    endif.


    field-symbols <t_xls> type standard table.
    assign mo_excel_table->* to <t_xls>.

    loop at it_structure assigning <structure>.

      data lv_current_row type sy-tabix.

      field-symbols <xls> type any.
      append initial line to <t_xls> assigning <xls>.

      mo_instance->fill_xls_table(
        exporting
          is_structure = <structure>
          iv_header = abap_true
        changing
          is_xls = <xls>
      ).

      data lv_total_rows type sy-tabix.
      describe table <t_xls> lines lv_total_rows.


      " Alimenta campos em branco que já passaram
      if lv_current_row <> lv_total_rows.

        add 1 to lv_current_row.
        field-symbols <xls_others> type any.
        loop at <t_xls> assigning <xls_others>
            from lv_current_row.

          field-symbols <field_from> type any.
          field-symbols <field_to> type any.

          do.
            assign component sy-index of structure <xls> to <field_from>.
            assign component sy-index of structure <xls_others> to <field_to>.

            if sy-subrc is not initial.
              exit.
            endif.

            if <field_from> is not initial and <field_to> is initial.
              <field_to> = <field_from>.
            endif.

          enddo.
        endloop.
      endif. " Alimenta campos em branco que já passaram

    endloop.


*    endloop.
    ro_instance = mo_instance.


  endmethod.                    "factory

  method generate.
    types:
      begin of lty_fields,
        structure type string,
        field type string,
      end of lty_fields.

    data:  lo_application   type  ole2_object,
           lo_workbook      type  ole2_object,
           lo_workbooks     type  ole2_object,
           lo_worksheet     type  ole2_object.

    data lt_structures type table of lvc_s_fcat-tabname.
    field-symbols <structure> like line of lt_structures.
    data lt_fields_all type table of lty_fields.
    data lt_fields type table of lty_fields.
    field-symbols <field> like line of lt_fields.
    data lv_initial_column type i value 1.
    data lv_end_column type i.

    data: lo_cellstart  type ole2_object,
          lo_cell       type ole2_object,
          lo_cellend    type ole2_object,
          lo_selection  type ole2_object,
          lo_range      type ole2_object.

    data lv_lines type i.


    create object lo_application 'Excel.Application'.
    call method of
        lo_application
        'Workbooks'    = lo_workbooks.
    call method of
        lo_workbooks
        'Add'        = lo_workbook.

    set property of lo_application 'Visible' = 0.
    get property of lo_application 'ACTIVESHEET' = lo_worksheet.


    field-symbols <excel_field_mapping> like line of mt_excel_field_mapping.
    loop at mt_excel_field_mapping assigning <excel_field_mapping>.

      collect <excel_field_mapping>-structure into lt_structures.
      data ls_fields like line of lt_fields_all.
      move-corresponding <excel_field_mapping> to ls_fields.
      collect ls_fields into lt_fields_all.
    endloop.

    loop at lt_structures assigning <structure>.

      lt_fields = lt_fields_all.
      delete lt_fields where structure <> <structure>.

      describe table lt_fields lines lv_lines.
      add lv_lines to lv_end_column.

* Select the Range of Cells:
      call method of
          lo_worksheet
          'cells'      = lo_cellstart
        exporting
          #1           = 1
          #2           = lv_initial_column.


      data lv_text type string.
      select single ddtext from dd02v
        into lv_text
        where tabname = <structure>
          and ddlanguage = 'P'.

      set property of lo_cellstart 'Value' = lv_text.

      call method of
          lo_worksheet
          'cells'      = lo_cellend
        exporting
          #1           = 1
          #2           = lv_end_column.
      call method of
          lo_worksheet
          'range'      = lo_range
        exporting
          #1           = lo_cellstart
          #2           = lo_cellend.

      call method of
          lo_range
          'select'.
      call method of
          lo_range
          'merge'.

      loop at lt_fields assigning <field>
        where structure = <structure>.

        call method of
            lo_worksheet
            'cells'      = lo_cellstart
          exporting
            #1           = 2
            #2           = lv_initial_column.


        data lv_rollname type dd03l-rollname.
        select single rollname from dd03l
          into lv_rollname
          where tabname = <field>-structure
            and fieldname = <field>-field.

        if sy-subrc is initial.

          select single ddtext from dd04t
            into lv_text
            where rollname = lv_rollname
              and ddlanguage = 'P'.

        endif.

        set property of lo_cellstart 'Value' = lv_text.

        add 1 to lv_initial_column.

      endloop.

    endloop.


    field-symbols <excel_table> type standard table.
    field-symbols <excel> type any.

    assign mo_excel_table->* to <excel_table>.
    data lv_row_num type i value 2.
    loop at <excel_table> assigning <excel>.
      add 1 to lv_row_num.
      do.

        field-symbols <excel_field> type any.
        data lv_tabix type i.
        lv_tabix = sy-index.
        assign component lv_tabix of structure <excel> to <excel_field>.
        if sy-subrc is initial.

          call method of
              lo_worksheet
              'cells'      = lo_cell
            exporting
              #1           = lv_row_num
              #2           = lv_tabix.

          set property of lo_cell 'Value' = <excel_field>.

        else.
          exit.
        endif.

      enddo.

    endloop.

    call method of
        lo_worksheet
        'SaveAs'

      exporting
        #1           = mv_path "name of excel
        #2           = 1. "file format

    call method of
        lo_application
        'quit'.
    free object lo_worksheet.
    free object lo_workbook.
    free object lo_application.

    message 'Arquivo salvo com sucesso' type 'S'.

  endmethod.                    "GENERATE

  method generate_xls_table.

    data lo_typedescr type ref to cl_abap_structdescr.

    if mo_random is not bound.
      mo_random = cl_abap_random_int=>create(
        min = 1
      ).
    endif.

    try .
        lo_typedescr ?= cl_abap_structdescr=>describe_by_data( is_structure ).
      catch cx_sy_move_cast_error.

        data lo_tab type ref to data.
        create data lo_tab like is_structure.
        field-symbols <tab> type standard table.
        assign lo_tab->* to <tab>.
        <tab> = is_structure.

        field-symbols <structure> type any.

        read table <tab> assigning <structure> index 1.
        if sy-subrc is initial.
          mo_instance->generate_xls_table(
            exporting
              is_structure = <structure> ).
        endif.
        return.
    endtry.

    data lt_components type cl_abap_structdescr=>component_table.
    field-symbols <component> like line of lt_components.

    lt_components = lo_typedescr->get_components( ).

    loop at lt_components assigning <component>.

      field-symbols <field> type any.
      assign component <component>-name of structure is_structure to <field>.
      if <component>-type->type_kind <> 'v' and <component>-type->type_kind <> 'h' and <component>-type->type_kind <> 'u'.

        field-symbols <fieldcat> like line of mt_fieldcat.
        append initial line to mt_fieldcat assigning <fieldcat>.

        <fieldcat>-fieldname = mo_random->get_next( ).
        shift <fieldcat>-fieldname left deleting leading space.
        <fieldcat>-tabname = lo_typedescr->get_relative_name( ).

        field-symbols <excel_field_mapping> like line of mt_excel_field_mapping.
        append initial line to mt_excel_field_mapping assigning <excel_field_mapping>.
        <excel_field_mapping>-structure = lo_typedescr->get_relative_name( ).
        <excel_field_mapping>-field = <component>-name.
        <excel_field_mapping>-fieldname = <fieldcat>-fieldname.

      else.

        generate_xls_table(
          exporting
            is_structure = <field>
        ).

      endif.

    endloop.


    if iv_header = abap_true.


      cl_alv_table_create=>create_dynamic_table(
        exporting
          it_fieldcatalog = mt_fieldcat
        importing
          ep_table = mo_excel_table
      ).


    endif.



  endmethod.                    "generate_xls_table


  method fill_xls_table.

    data lo_typedescr type ref to cl_abap_structdescr.


    try .
        lo_typedescr ?= cl_abap_structdescr=>describe_by_data( is_structure ).
      catch cx_sy_move_cast_error.

        data lo_tab type ref to data.
        create data lo_tab like is_structure.
        field-symbols <tab> type standard table.
        assign lo_tab->* to <tab>.
        <tab> = is_structure.

        field-symbols <structure> type any.

        loop at <tab> assigning <structure>.

          field-symbols <t_xls> type standard table.

          if sy-tabix = 1.

            mo_instance->fill_xls_table(
              exporting
                is_structure = <structure>
              changing
                is_xls = is_xls ).
          else.

            assign mo_excel_table->* to <t_xls>.
            field-symbols <xls> type any.
            append initial line to <t_xls> assigning <xls>.

            move-corresponding is_xls to <xls>.

            mo_instance->fill_xls_table(
              exporting
                is_structure = <structure>
              changing
                is_xls = <xls> ).

          endif.

        endloop.

        return.
    endtry.

    data lt_components type cl_abap_structdescr=>component_table.
    field-symbols <component> like line of lt_components.

    lt_components = lo_typedescr->get_components( ).

    loop at lt_components assigning <component>.

      field-symbols <field_from> type any.
      assign component <component>-name of structure is_structure to <field_from>.
      if <component>-type->type_kind <> 'v' and <component>-type->type_kind <> 'h' and <component>-type->type_kind <> 'u'.

        field-symbols <field_to> type any.

        data ls_structure_name type lvc_s_fcat-tabname.
        ls_structure_name = lo_typedescr->get_relative_name( ).

        field-symbols <field_mapping> like line of mt_excel_field_mapping.
        read table mt_excel_field_mapping assigning <field_mapping>
          with key structure = ls_structure_name
                   field = <component>-name.

        if sy-subrc is initial.

          assign component <field_mapping>-fieldname of structure is_xls to <field_to>.
          <field_to> = <field_from>.

        endif.

*        field-symbols <excel_out> like line of mt_excel_out.
*        append initial line to mt_excel_out assigning <excel_out>.
*        <excel_out>-structure = lo_typedescr->get_relative_name( ).
*        <excel_out>-field = <component>-name.
*        <excel_out>-value = <field>.

      else.

        fill_xls_table(
          exporting
            is_structure = <field_from>
          changing
            is_xls = is_xls
        ).

      endif.

    endloop.


  endmethod.                    "generate_xls_table



endclass.                    "lcl_excel_gen IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS lcl_selection IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_selection implementation.

  method get_instance.

    if mo_instance is not bound.
      create object mo_instance.
    endif.

    ro_instance = mo_instance.

  endmethod.                    "constructor

  method get_begda.

    rv_begda = mv_begda.

  endmethod.                    "get_begda

  method get_endda.
    rv_endda = mv_endda.
  endmethod.                    "get_endda

  method set_begda.
    mv_begda = iv_begda.
  endmethod.                    "set_begda

  method set_endda.
    mv_endda = iv_endda.
  endmethod.                    "set_endda

  method set_pernr.

    data lo_org_assign type ref to cl_hrpadbr_org_assign.
    data lo_employee type ref to cl_hrpadbr_employee.
    data lo_pers_master_data type ref to cl_hrpadbr_master_data.
    data lo_pay_utils type ref to cl_hrpaybr_efde_payroll_utils.
    data lv_bukrs type bukrs.
    data lv_actual_index type sy-tabix.

    field-symbols <employee> like line of mt_employees.

    append initial line to mt_employees assigning <employee>.
    lv_actual_index = sy-tabix.

    <employee>-pernr = iv_pernr.

    create object lo_employee
      exporting
        iv_pernr = <employee>-pernr.

    lo_pers_master_data = lo_employee->get_master_data( ).

    try .
        <employee>-cpf_nr = lo_pers_master_data->get_cpf( ).
        lo_org_assign ?= lo_employee->get_last( iv_infty = if_hrpadbr_infotype=>gc_org_assign
                                                iv_begda = mv_begda
                                                iv_endda = mv_endda ).
      catch cx_hrpadbr_infty_not_found.
        delete mt_employees index lv_actual_index.
        return.
    endtry.

    lv_bukrs = lo_org_assign->ms_org_assign-bukrs.
    lo_pay_utils = cl_hrpaybr_efde_payroll_utils=>get_instance( ).

    <employee>-inf_value = lo_pay_utils->get_payroll_inf_value(
                                        iv_bukrs        = lv_bukrs
                                        iv_ee_cpf       = <employee>-cpf_nr
                                        iv_payroll_ind  = if_hrpaybr_efd_constants_c=>gc_event_header-payroll_ind_monthly ).

  endmethod.                    "set_pernr

  method set_event_type.

    field-symbols <parameter> type any.
    assign ('P_5001') to <parameter>.

    if sy-subrc is initial.
      if <parameter> = abap_true.
        mv_event_type = '5001'.
      else.
        mv_event_type = '5002'.
      endif.
    endif.

    assign ('P_5011') to <parameter>.
    if sy-subrc is initial.
      if <parameter> = abap_true.
        mv_event_type = '5011'.
      else.
        mv_event_type = '5012'.
      endif.
    endif.


    field-symbols <event_type> like line of mr_origin_event_type.
*    APPEND INITIAL LINE TO mr_origin_event_type ASSIGNING <event_type>.
*    <event_type> = 'IEQ'.
    case mv_event_type.
      when '5001'.
        append initial line to mr_origin_event_type assigning <event_type>.
        <event_type> = 'IEQ'.
        <event_type>-low = '0101'.                          " S-1200

        append initial line to mr_origin_event_type assigning <event_type>.
        <event_type> = 'IEQ'.
        <event_type>-low = '0314'.                          " S-2299

        append initial line to mr_origin_event_type assigning <event_type>.
        <event_type> = 'IEQ'.
        <event_type>-low = '0403'.                          " S-2399
      when '5002'.
        append initial line to mr_origin_event_type assigning <event_type>.
        <event_type> = 'IEQ'.
        <event_type>-low = '0102'.                          " S-1210
      when '5011' or '5012'.
        append initial line to mr_origin_event_type assigning <event_type>.
        <event_type> = 'IEQ'.
        <event_type>-low = '0105'.

        append initial line to mr_origin_event_type assigning <event_type>.
        <event_type> = 'IEQ'.
        <event_type>-low = '0107'.
    endcase.


  endmethod.                    "set_event_type

  method get_event_type.

    rv_event_type = mv_event_type.

  endmethod.                    "get_event_type

  method get_employees.

    rt_employees = mt_employees.

  endmethod.                    "get_employees

  method set_bukrs.

    mt_bukrs = it_bukrs.

  endmethod.                    "set_bukrs

  method get_bukrs.
    rt_bukrs = mt_bukrs.
  endmethod.                    "get_bukrs

  method get_origin_event_type_range.

    rr_event_type = mr_origin_event_type.

  endmethod.                    "get_ORIGIN_event_type_range

endclass.                    "lcl_selection IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS lcl_app IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_app implementation.


  method get_instance.

    if mo_instance is not bound.
      create object mo_instance.
    endif.

    r_instance = mo_instance.

  endmethod.                    "get_instance

  method main.

    call screen 9000.

  endmethod.                    "main

  method get_selection.

    if mo_selection is not bound.
      mo_selection = lcl_selection=>get_instance( ).
    endif.

    ro_selection = mo_selection.

  endmethod.                    "get_selection

  method pre_check.

    data lr_event_type type range of t7brefd_event-event_type.
    data lv_begda type begda.
    data lv_endda type endda.

    lv_begda = mo_selection->get_begda( ).
    lv_endda = mo_selection->get_endda( ).
    lr_event_type = mo_selection->get_origin_event_type_range( ).

    select count( * ) from t7brefd_event
      where event_type in lr_event_type
        and status = '3'
        and begda >= lv_begda
        and endda <= lv_endda.

    if sy-subrc is not initial.
      raise exception type cx_hrpaybr_efdf_generators .
    endif.

  endmethod.                    "pre_check

  method pbo.

    data lo_structure type ref to data.
    data lv_structure_type type string.
    field-symbols <structure_tab> type standard table.
    field-symbols <structure> type any.


*    data lt_structure type table of ytbhr_s5001.

    set pf-status '9000'.
    set titlebar '9000'.

    if lo_tree is bound.
      return.
    endif.


    data lv_event_type type t7brefd_evtype-event_type.
    lv_event_type = mo_selection->get_event_type( ).

    case lv_event_type.
      when '5001'.
        lv_structure_type = 'YTBHR_S5001'.
      when '5002'.
        lv_structure_type = 'YTBHR_S5002'.
      when '5011'.
        lv_structure_type = 'YTBHR_S5011'.
      when '5012'.
        lv_structure_type = 'YTBHR_S5012'.
    endcase.

    create data mo_structure type table of (lv_structure_type).
    assign mo_structure->* to <structure_tab>.


    me->get_generated_events(
      importing
        et_structure = <structure_tab>
    ).

    if <structure_tab> is initial.
      message 'Não há dados para exibição!' type 'S' display like 'E'.
      leave to screen 0.
    endif.

    create object mo_main_container
      exporting
        extension = 9999.

    create object mo_splitter_container
      exporting
        parent  = mo_main_container
        rows    = 1
        columns = 2.

    mo_container_menu = mo_splitter_container->get_container(
      row = 1
      column = 1
    ).

    mo_container_content = mo_splitter_container->get_container(
      row = 1
      column = 2
    ).

    mo_splitter_container->set_column_width(
      exporting
        id = 1
        width = 20
    ).

    create object lo_tree
      exporting
        parent              = mo_container_menu
        node_selection_mode = cl_gui_simple_tree=>node_sel_mode_single.

    data:
            lt_events type cntl_simple_events,
            ls_event type cntl_simple_event.

    ls_event-eventid = cl_gui_simple_tree=>eventid_node_double_click.
    ls_event-appl_event = 'X'. " process PAI if event occurs
    append ls_event to lt_events.

    lo_tree->set_registered_events( lt_events ).

    set handler me->node_double_click for lo_tree.



*    field-symbols <structure> like line of lt_structure.
    field-symbols <data> type any.

    loop at <structure_tab> assigning <structure>.

      data lt_node_table type ty_ytbhr_mtreesnode.
      data lo_typedescr type ref to cl_abap_structdescr.
      data lo_data type ref to data.

      create data lo_data like <structure>.
      assign lo_data->* to <data>.
      <data> = <structure>.

      lo_typedescr ?= cl_abap_structdescr=>describe_by_data( <structure> ).
      me->convert_structure_to_node(
        exporting
          io_rtts = lo_typedescr
          io_structure = lo_data
        changing
          ct_node = lt_node_table
          ct_mapped_nodekey = t_mapped_nodekey
      ).

      lo_tree->add_nodes(
        table_structure_name = 'YTBHR_MTREESNODE'
        node_table = lt_node_table
      ).
      clear lt_node_table.

    endloop.

  endmethod.                    "pbo

  method convert_structure_to_node.

    data lo_typedescr type ref to cl_abap_structdescr.
    data lo_datadescr type ref to cl_abap_datadescr.
    data lo_tabledescr type ref to cl_abap_tabledescr.
    data lo_elem_descr type ref to cl_abap_elemdescr.
    data lt_components type cl_abap_structdescr=>component_table.
    data lv_node_key type ytbhr_mtreesnode-node_key.
    data lv_text type ytbhr_mtreesnode-text.
    data lv_relatkey like iv_relatkey.

    field-symbols <structure_data> type any.
    field-symbols <component> like line of lt_components.
    field-symbols <substructure> type any.
    field-symbols <data> type any.

    data lo_data type ref to data.

    lv_relatkey = iv_relatkey.

    try.
        call method io_rtts->('GET_COMPONENTS')
          receiving
            p_result = lt_components.
      catch cx_sy_dyn_call_illegal_method.

        field-symbols <structure_data_tab> type standard table.
        assign io_structure->* to <structure_data_tab>.

        loop at <structure_data_tab> assigning <structure_data>.

          create data lo_data like <structure_data>.
          assign lo_data->* to <data>.
          <data> = <structure_data>.

          call method io_rtts->('GET_TABLE_LINE_TYPE')
            receiving
              p_descr_ref = lo_datadescr.

          lo_typedescr ?= lo_datadescr.

          me->convert_structure_to_node(
            exporting
              io_rtts = lo_typedescr
              io_structure = lo_data
              iv_relatkey = lv_relatkey
            changing
              ct_node = ct_node
              ct_mapped_nodekey = ct_mapped_nodekey
          ).

        endloop.
        return.
    endtry.


    data lo_random type ref to cl_abap_random.
    lo_random = cl_abap_random=>create( ).


    loop at lt_components assigning <component>.

      if <component>-type->type_kind <> 'v' and
         <component>-type->type_kind <> 'u' and
         <component>-type->type_kind <> 'h'.
        continue.
      endif.

      data lv_tabname type char50.

      lv_tabname = <component>-type->get_relative_name( ).
*      replace regex '^.+\=' in lv_tabname with space.

      select single ddtext
        from dd02t
        into lv_text
        where tabname = lv_tabname
          and ddlanguage = 'P'.

      if sy-subrc is not initial.

        select single ddtext
          from dd40t
          into lv_text
          where typename = lv_tabname
          and ddlanguage = 'P'.

      endif.

      if <component>-type->type_kind = 'h'.
        field-symbols <substructure_tab> type standard table.
        assign io_structure->* to <structure_data>.
        assign component <component>-name of structure <structure_data> to <substructure_tab>.

        read table <substructure_tab> assigning <substructure> index 1.
        if sy-subrc is initial.
          lo_typedescr ?= cl_abap_structdescr=>describe_by_data( <substructure> ).
          if lo_typedescr->type_kind = 'v'.

            loop at <substructure_tab> assigning <substructure>.

              create data lo_data like <substructure>.
              assign lo_data->* to <data>.
              <data> = <substructure>.

              do.
                lv_node_key = lo_random->seed( ).
                read table mt_generated_node_key
                  with key table_line = lv_node_key
                    transporting no fields.
                if sy-subrc is not initial.
                  append lv_node_key to mt_generated_node_key.
                  exit.
                endif.
              enddo.
*              lv_node_key = lo_random->seed( ).

              data lv_structure_name type dd02t-tabname.
              lv_structure_name = lv_tabname.

              me->insert_node_into_table(
                exporting
                  iv_node_key = lv_node_key
                  iv_text = lv_text
                  iv_relatkey = lv_relatkey
                  io_structure = lo_data
                  iv_structure_name = lv_structure_name
                changing
                  ct_node_table = ct_node
                  ct_mapped_nodekey = ct_mapped_nodekey
              ).

*          data lo_typedescr type ref to cl_abap_structdescr.
              lo_typedescr ?= cl_abap_structdescr=>describe_by_data( <substructure> ).

              me->convert_structure_to_node(
                exporting
                  io_rtts = lo_typedescr
                  io_structure = lo_data
                  iv_relatkey = lv_node_key
                  changing
                    ct_node = ct_node
                    ct_mapped_nodekey = ct_mapped_nodekey
              ).

            endloop.

          else.

            assign io_structure->* to <structure_data>.
            assign component <component>-name of structure <structure_data> to <substructure_tab>.

*            lv_node_key = lo_random->seed( ).
            do.
              lv_node_key = lo_random->seed( ).
              read table mt_generated_node_key
                with key table_line = lv_node_key
                  transporting no fields.
              if sy-subrc is not initial.
                append lv_node_key to mt_generated_node_key.
                exit.
              endif.
            enddo.

            lv_structure_name = lv_tabname.


            create data lo_data like <substructure_tab>.
            assign lo_data->* to <data>.
            <data> = <substructure_tab>.

            me->insert_node_into_table(
              exporting
                iv_node_key = lv_node_key
                iv_text = lv_text
                iv_relatkey = lv_relatkey
                io_structure = lo_data
                iv_structure_name = lv_structure_name
              changing
                ct_node_table = ct_node
                ct_mapped_nodekey = ct_mapped_nodekey
            ).

            lo_tabledescr ?= cl_abap_structdescr=>describe_by_data( <substructure_tab> ).

            me->convert_structure_to_node(
              exporting
                io_rtts = lo_tabledescr
                io_structure = lo_data
                iv_relatkey = lv_node_key
                changing
                  ct_node = ct_node
                  ct_mapped_nodekey = ct_mapped_nodekey
            ).

          endif.
        endif.

      else.

        assign io_structure->* to <structure_data>.
        assign component <component>-name of structure <structure_data> to <substructure>.

        create data lo_data like <substructure>.
        assign lo_data->* to <data>.
        <data> = <substructure>.
*        lv_node_key = lo_random->seed( ).
        do.
          lv_node_key = lo_random->seed( ).
          read table mt_generated_node_key
            with key table_line = lv_node_key
              transporting no fields.
          if sy-subrc is not initial.
            append lv_node_key to mt_generated_node_key.
            exit.
          endif.
        enddo.

        if <component>-name = 'EVENT'.

          field-symbols <inf_value> type any.
          field-symbols <inf_type> type any.
          assign component 'INF_VALUE' of structure <substructure> to <inf_value>.
          assign component 'INF_TYPE' of structure <substructure> to <inf_type>.

          data lt_employees type lcl_selection=>ty_t_employees.
          field-symbols <employee> like line of lt_employees.

          lt_employees = mo_selection->get_employees( ).

          read table lt_employees assigning <employee>
            with key inf_value = <inf_value>.

          if sy-subrc is initial.
            data lo_screen_conv type ref to cl_hrpaybr_efdf_screen_conv.
            lo_screen_conv = cl_hrpaybr_efdf_screen_conv=>get_instance( ).
            lv_text = lo_screen_conv->inf_value_to_output(
                          iv_inf_type  = <inf_type>
                          iv_inf_value = <inf_value> ).
          endif.
        endif.

        lv_structure_name = lv_tabname.
        me->insert_node_into_table(
          exporting
            iv_node_key = lv_node_key
            iv_text = lv_text
            iv_relatkey = lv_relatkey
            io_structure = lo_data
            iv_structure_name = lv_structure_name
          changing
            ct_node_table = ct_node
            ct_mapped_nodekey = ct_mapped_nodekey
        ).

        if <component>-name = 'EVENT'.
          lv_text = 'Funcionário X'.
          lv_relatkey = lv_node_key.
        endif.

        me->convert_structure_to_node(
          exporting
            io_rtts = <component>-type
            io_structure = lo_data
            iv_relatkey = lv_node_key
            changing
              ct_node = ct_node
              ct_mapped_nodekey = ct_mapped_nodekey
        ).
      endif.

    endloop.

  endmethod.                    "convert_structure_to_node

  method pai.

    if i_ucomm = 'EXPORT'.
      me->export_excel( ).
    endif.

  endmethod.                    "pai

  method exit.

    if i_ucomm = 'ECAN'.
      leave program.
    endif.

    leave to screen 0.


  endmethod.                    "exit
  method get_generated_events.

    data lt_events type table of t7brefd_event.
    data lt_documents_links type table of t7brefd_doclnk.
    data lt_documents type table of t7br_documents.
    data lt_employees type lcl_selection=>ty_t_employees.
    data lv_event_type type t7brefd_evtype-event_type.
    data lr_event_type type range of t7brefd_evtype-event_type.
    data lv_begda type begda.
    data lv_endda type endda.
    data lv_xml type xstring.
    data lv_xml_in type string.
*    DATA ls_structure TYPE ytbhr_s5001.
    data lt_bukrs type range of bukrs.


    lt_employees = me->mo_selection->get_employees( ).
    lv_event_type = me->mo_selection->get_event_type( ).
    lv_begda = me->mo_selection->get_begda( ).
    lv_endda = me->mo_selection->get_endda( ).
    lt_bukrs = me->mo_selection->get_bukrs( ).
    lr_event_type = me->mo_selection->get_origin_event_type_range( ).


    if lv_event_type < '5011'.

      select * from t7brefd_event
        into table lt_events
        for all entries in lt_employees
          where event_type in lr_event_type
            and status = 3
            and inf_value = lt_employees-inf_value
            and begda >= lv_begda
            and endda <= lv_endda
            and bukrs in lt_bukrs.

      select * from t7brefd_event
        appending table lt_events
        for all entries in lt_employees
          where event_type in lr_event_type
            and status = 3
            and inf_value = lt_employees-inf_value2
            and begda >= lv_begda
            and endda <= lv_endda
            and bukrs in lt_bukrs.

    else.

      select * from t7brefd_event
        into table lt_events
          where event_type in lr_event_type
            and status = 3
            and begda >= lv_begda
            and endda <= lv_endda
            and bukrs in lt_bukrs.

    endif.

    if lt_events is not initial.

      sort lt_events by event_id.

      data lv_esocial_doc_type type t7brefd_doclnk-esocial_doc_type.
      concatenate 'TOT' lv_event_type into lv_esocial_doc_type.
*      lv_esocial_doc_type = 'TOT' && lv_event_type.

      select * from t7brefd_doclnk
        into table lt_documents_links
        for all entries in lt_events
          where esocial_id = lt_events-event_id
            and esocial_doc_type = lv_esocial_doc_type.

      if sy-subrc is initial.

        sort lt_documents_links by document_id.

        select * from t7br_documents
          into table lt_documents
          for all entries in lt_documents_links
          where document_id = lt_documents_links-document_id.

        field-symbols <document> like line of lt_documents.

        loop at lt_documents assigning <document>.

          field-symbols <document_link> like line of lt_documents_links.
          read table lt_documents_links assigning <document_link>
            with key document_id = <document>-document_id
              binary search.

          if sy-subrc is initial.

            field-symbols <event> like line of lt_events.
            read table lt_events assigning <event>
              with key event_id = <document_link>-esocial_id
                binary search.
          endif.

          call transformation yhrpaybr_efde_remove_attrs
          source xml <document>-document_string
          result xml lv_xml.


          data lv_transformation type string.
          data lv_structure_type type string.
          case lv_event_type.
            when '5001'.
              lv_transformation = 'YHRPAYBR_EFDE_S5001'.
              lv_structure_type = 'YTBHR_S5001'.
            when '5002'.
              lv_transformation = 'YHRPAYBR_EFDE_S5002'.
              lv_structure_type = 'YTBHR_S5002'.
            when '5011'.
              lv_transformation = 'YHRPAYBR_EFDE_S5011'.
              lv_structure_type = 'YTBHR_S5011'.
            when '5012'.
              lv_transformation = 'YHRPAYBR_EFDE_S5012'.
              lv_structure_type = 'YTBHR_S5012'.
          endcase.

          data lo_structure type ref to data.
          field-symbols <structure> type any.
          create data lo_structure type (lv_structure_type).
          assign lo_structure->* to <structure>.


          try.
              call transformation (lv_transformation)
              source xml lv_xml
              result structure = <structure>.
            catch cx_xslt_format_error.
              continue.
          endtry.

          field-symbols <str_event> type any.
          assign component 'EVENT' of structure <structure> to <str_event>.
          move-corresponding <event> to <str_event>.

          append <structure> to et_structure.

        endloop.

      endif.
    endif.

  endmethod.                    "get_generated_events
  method node_double_click.

    data: lo_outtab type ref to data.
    field-symbols <outtab> type standard table.
    field-symbols <out> type any.
    data lv_type type typ.
    data lo_structdescr type ref to cl_abap_structdescr.
    data lt_components type lo_structdescr->component_table.
    data lv_structname type dd02l-tabname.
    data lt_fieldcat type lvc_t_fcat.


    field-symbols <mapped_nodekey> like line of t_mapped_nodekey.
    read table t_mapped_nodekey assigning <mapped_nodekey>
      with key nodekey = node_key.

    if sy-subrc is initial.

      assign <mapped_nodekey>-content->* to <out>.
      describe field <out> type lv_type.

      case lv_type.
*        when 'u'.
*          create data lo_outtab like table of <out>.
*          assign lo_outtab->* to <outtab>.
*          insert <out> into table <outtab>.
        when 'h'.
          data lo_tabledescr type ref to cl_abap_tabledescr.
          field-symbols <content_tab> type standard table.

          assign <mapped_nodekey>-content->* to <content_tab>.
          lo_tabledescr ?= cl_abap_tabledescr=>describe_by_data( <content_tab> ).
          data lo_line_type type ref to cl_abap_datadescr.
          lo_line_type = lo_tabledescr->get_table_line_type( ).
          lv_structname = lo_line_type->get_relative_name( ).

          call function 'LVC_FIELDCATALOG_MERGE'
            exporting
              i_structure_name = lv_structname
            changing
              ct_fieldcat      = lt_fieldcat.

          cl_alv_table_create=>create_dynamic_table(
            exporting
              it_fieldcatalog = lt_fieldcat
            importing
              ep_table = lo_outtab
          ).

          assign lo_outtab->* to <outtab>.

          field-symbols <ot> type any.
          field-symbols <ct> type any.

          loop at <content_tab> assigning <ct>.
            append initial line to <outtab> assigning <ot>.
            move-corresponding <ct> to <ot>.
          endloop.

        when 'v' or 'u'.
          lo_structdescr ?= cl_abap_structdescr=>describe_by_data( <out> ).
          lv_structname = lo_structdescr->get_relative_name( ).
          call function 'LVC_FIELDCATALOG_MERGE'
            exporting
              i_structure_name = lv_structname
            changing
              ct_fieldcat      = lt_fieldcat.

          field-symbols <fieldcat> like line of lt_fieldcat.
          loop at lt_fieldcat assigning <fieldcat>.
            field-symbols <field> type any.
            assign component <fieldcat>-fieldname of structure <out> to <field>.
            if sy-subrc is not initial.
              delete lt_fieldcat index sy-tabix.
            endif.

          endloop.

          cl_alv_table_create=>create_dynamic_table(
            exporting
              it_fieldcatalog = lt_fieldcat
            importing
              ep_table = lo_outtab
          ).

          assign lo_outtab->* to <outtab>.
          append initial line to <outtab> assigning <ot>.
          move-corresponding <out> to <ot>.

      endcase.

      if mo_alv is bound.

        mo_alv->set_data(
          changing
            t_table = <outtab>
        ).

        mo_alv->refresh( ).

      else.

        cl_salv_table=>factory(
          exporting
            r_container = mo_container_content
          importing
            r_salv_table = mo_alv
          changing
            t_table = <outtab>
        ).

        mo_alv->display( ).

      endif.

    endif.

  endmethod.                    "node_double_click

  method insert_node_into_table.

    field-symbols <node> like line of ct_node_table.
    field-symbols <data> type any.

    assign io_structure->* to <data>.

    append initial line to ct_node_table assigning <node>.
    <node>-node_key = iv_node_key.
    <node>-isfolder = abap_true.
    <node>-text = iv_text.

    if iv_relatkey is not initial.

      <node>-relatkey = iv_relatkey.
      <node>-relatship = cl_gui_simple_tree=>relat_last_child.

    endif.

    field-symbols <mapped_nodekey> like line of ct_mapped_nodekey.
    append initial line to ct_mapped_nodekey assigning <mapped_nodekey>.
    <mapped_nodekey>-nodekey = iv_node_key.
    <mapped_nodekey>-content = io_structure.
    <mapped_nodekey>-structure_name = iv_structure_name.

  endmethod.                    "build_node_table

  method export_excel.

    field-symbols <structure_tab> type standard table.
    field-symbols <structure> type any.
    data lo_typedescr type ref to cl_abap_structdescr.
    data lt_components type cl_abap_structdescr=>component_table.
    data lo_excel_gen type ref to lcl_excel_gen.

    data lv_path type string.
    data lv_dummy type string.
    cl_gui_frontend_services=>file_save_dialog(
      exporting
        default_file_name = 'export.xls'
      changing
        path = lv_dummy
        fullpath = lv_path
        filename = lv_dummy
    ).


    assign mo_structure->* to <structure_tab>.
    lo_excel_gen = lcl_excel_gen=>factory(
      it_structure = <structure_tab>
      iv_path = lv_path
    ).

    lo_excel_gen->generate( ).

  endmethod.                    "export_excel

endclass.                    "lcl_app IMPLEMENTATION
