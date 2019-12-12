*&---------------------------------------------------------------------*
*& Report       YHRBR_EFD_S5000_REPORT
*& Descrição    Totalizadores eSocial para eventos de fechamento
*&            (S-5011 e S-5012)
*&---------------------------------------------------------------------*
*&
*& Autor: Vinicius Barrionuevo (Solutio IT)
*& Data: 01/08/2018
*&
*&---------------------------------------------------------------------*

report  yhrbr_efd_tot_er_report.

data gv_bukrs type bukrs.
selection-screen begin of block b1 with frame title text-s01.
select-options s_bukrs for gv_bukrs.

parameters:p_begda  type begda default '18000101' no-display.
parameters:p_endda  type endda default '99991231' no-display.

parameters:p_refdt  type hrpadbr_efd_table_ref_date default sy-datum obligatory.

selection-screen end of block b1.

selection-screen begin of block b2 with frame title text-s02.
parameters: p_5011 type c radiobutton group g1.
parameters: p_5012 type c radiobutton group g1.
selection-screen end of block b2.

include yhrbr_efd_tot_report_cd.
include yhrbr_efd_tot_report_ci.

data o_app type ref to lcl_app.
data o_selection type ref to lcl_selection.

initialization.

  o_app = lcl_app=>get_instance( ).

at selection-screen.
  if p_begda > p_endda.
    message e003(pn) with p_begda p_endda.
  endif.

start-of-selection.

  o_selection = o_app->get_selection( ).

  call function 'RP_LAST_DAY_OF_MONTHS'
    exporting
      day_in            = p_refdt
    importing
      last_day_of_month = p_endda.

  concatenate p_refdt(6) '01' into p_begda.

  o_selection->set_begda( p_begda ).
  o_selection->set_endda( p_endda ).
  o_selection->set_event_type( ).
  o_selection->set_bukrs( s_bukrs[] ).


end-of-selection.

  o_app->main( ).



*----------------------------------------------------------------------*
*  MODULE pbo_9000 OUTPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
module pbo_9000 output.

  o_app->pbo( ).

endmodule.                    "pbo_9000 OUTPUT

*----------------------------------------------------------------------*
*  MODULE pai_9000 INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
module pai_9000 input.

  o_app->pai( sy-ucomm ).

endmodule.                    "pai_9000 INPUT

*----------------------------------------------------------------------*
*  MODULE exit INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
module exit input.

  o_app->exit( sy-ucomm ).

endmodule.                    "exit INPUT
