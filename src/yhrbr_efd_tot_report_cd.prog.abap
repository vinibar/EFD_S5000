*&---------------------------------------------------------------------*
*&  Include           YHRBR_EFD_S5000_REPORT_CD
*&---------------------------------------------------------------------*
class lcl_excel_gen definition create private.
  public section.
    types:
    begin of ty_excel_field_mapping,
      structure type lvc_s_fcat-tabname,
      field type lvc_s_fcat-fieldname,
      fieldname type lvc_s_fcat-fieldname,
    end of ty_excel_field_mapping.
    types: ty_t_excel_field_mapping type table of ty_excel_field_mapping.

    class-methods:
      factory
        importing
          it_structure type standard table
          iv_path type string
        returning value(ro_instance) type ref to lcl_excel_gen.

    methods:
      generate.

  protected section.
    class-data mt_excel_field_mapping type ty_t_excel_field_mapping.
    class-data mo_excel_table type ref to data.
    class-data mt_fieldcat type lvc_t_fcat.
    class-data mo_instance type ref to lcl_excel_gen.
    class-data mo_random type ref to cl_abap_random_int.
    class-data mv_path type string.

    methods:
      generate_xls_table
        importing
          iv_header type sap_bool optional
          is_structure type any,

      fill_xls_table
        importing
          iv_header type sap_bool optional
          is_structure type any
        changing
          is_xls type any.
endclass.                    "lcl_excel_gen DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_selection DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_selection definition create private.

  public section.

    types:
      begin of ty_employees,
        pernr type p0465-pernr,
        cpf_nr type p0465-cpf_nr,
        inf_value type hrpadbr_efd_inf_value,
        inf_value2 type hrpadbr_efd_inf_value,
      end of ty_employees,

      ty_r_event_type type range of t7brefd_evtype-event_type,

      ty_t_employees type table of ty_employees with default key,
      ty_t_bukrs type range of bukrs.

    class-methods:
      get_instance
        returning value(ro_instance) type ref to lcl_selection.

    methods:
      get_begda
        returning value(rv_begda) type begda,
      get_endda
        returning value(rv_endda) type endda,
      set_begda
        importing
          iv_begda type begda,
      set_endda
        importing
         iv_endda type endda,
      set_pernr
        importing
          iv_pernr type pernr_d,
      set_event_type,
      set_bukrs
        importing
          it_bukrs type ty_t_bukrs,
       get_bukrs
        returning value(rt_bukrs) type ty_t_bukrs,
      get_event_type
        returning value(rv_event_type) type t7brefd_evtype-event_type,
      get_origin_event_type_range
        returning value(rr_event_type) type ty_r_event_type,
      get_employees
        returning value(rt_employees) type ty_t_employees.

  private section.

    class-data:
      mo_instance type ref to lcl_selection.

    data mv_begda type begda.
    data mv_endda type endda.
    data mt_employees type ty_t_employees.
    data mv_event_type type t7brefd_evtype.
    data mt_bukrs type range of bukrs.
    data mr_origin_event_type type range of t7brefd_event-event_type.


endclass.                    "lcl_selection DEFINITION



*----------------------------------------------------------------------*
*       CLASS lcl_app DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
class lcl_app definition create private.

  public section.

    types:
      begin of ty_selected_employees,
        pernr type p0465-pernr,
        cpf_nr type p0465-cpf_nr,
        inf_value type hrpadbr_efd_inf_value,
      end of ty_selected_employees.

    types:
      ty_ytbhr_mtreesnode type table of ytbhr_mtreesnode with default key.

    types: ty_t_selected_employees type table of ty_selected_employees with default key.

    types:
      begin of ty_mapped_nodekey,
        nodekey type ytbhr_mtreesnode-node_key,
        content type ref to data,
        structure_name type dd02l-tabname,
      end of ty_mapped_nodekey,

      ty_t_mapped_nodekey type table of ty_mapped_nodekey.


    class-methods:
      get_instance
        returning value(r_instance) type ref to lcl_app.

    methods:
     main,

   get_selection
     returning value(ro_selection) type ref to lcl_selection,
  pre_check
  raising
      cx_hrpaybr_efdf_generators,
 pbo,
 pai
   importing
     value(i_ucomm) type sy-ucomm,
 exit
   importing
     value(i_ucomm) type sy-ucomm,
 node_double_click
  for event node_double_click
    of cl_gui_simple_tree
      importing
        node_key.

  private section.

    class-data mo_instance type ref to lcl_app.
    data mo_selection type ref to lcl_selection.
    data mo_structure type ref to data.
    data t_mapped_nodekey type ty_t_mapped_nodekey.
    data mo_main_container type ref to cl_gui_docking_container.
    data mo_splitter_container type ref to cl_gui_splitter_container.
    data mo_container_menu type ref to cl_gui_container.
    data mo_container_content type ref to cl_gui_container.
    data mo_alv type ref to cl_salv_table.
    data mt_generated_node_key type table of ytbhr_mtreesnode-node_key.

    data lo_tree type ref to cl_gui_simple_tree.


    methods:
      get_generated_events
        exporting
          et_structure type standard table.

    methods:
      insert_node_into_table
        importing
          iv_node_key type ytbhr_mtreesnode-node_key
          iv_text type ytbhr_mtreesnode-text
          iv_relatkey type ytbhr_mtreesnode-relatkey optional
          io_structure type ref to data
          iv_structure_name type dd02t-tabname
        changing
          ct_node_table type ty_ytbhr_mtreesnode
          ct_mapped_nodekey type ty_t_mapped_nodekey.


    methods:
      convert_structure_to_node
        importing
          io_rtts type ref to object
          io_structure type ref to data optional
          iv_relatkey type ytbhr_mtreesnode-relatkey optional
        changing
          ct_node type ty_ytbhr_mtreesnode
          ct_mapped_nodekey type ty_t_mapped_nodekey.

    methods:
      export_excel.



endclass.                    "lcl_app DEFINITION
