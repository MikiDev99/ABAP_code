
"Restituisce la testata di una tabella ddic
PERFORM GET_HEADER_FROM_DDIC    using    XV_TAB_NAME type STRING
                                changing YV_HEADER   type STRING .
                     
"Restituisce una tabella di stringhe separate da ;                     
PERFORM UPLOAD_LOCAL_EXCEL      using    XV_FILENAME    type STRING
                                         XV_HEADER      type FLAG
                                changing YT_FILE_STRING type STRING_TABLE.
 
"Restituisce una tabella di stringhe
PERFORM UPLOAD_LOCAL_CSV        using    XV_FILENAME    type STRING
                                changing YT_FILE_STRING type STRING_TABLE.

"Fornisce help per selezionare directory locale o server
PERFORM HELP_F4_INPUT_DIR       using X_OPTION type CHAR1
                                      XV_TITLE type STRING optional
                                      XV_DIR   type STRING.
                                 
"Restituisce la directory locale del desktop
PERFORM GET_LOCAL_DESKTOP_DIR   changing XV_DIR type STRING .

"Mostra generico ALV con SALV_TABLE
PERFORM DISPLAY_GENERIC_ALV     using    XV_TITLE type LVC_TITLE
                                         X_POPUP  type CHAR1
                                changing XT_TABLE type STANDARD TABLE.

"Restitusce un record trasposto
PERFORM GET_TRANSPOSED_TABLE    changing YO_DATA_TRANSP type DATA
                                         YT_FCAT_TRANSP type LVC_T_FCAT
                                         XT_TABLE       type STANDARD TABLE.

"Gestisce .xls .xlsx .csv per SAP
PERFORM UPLOAD_LOCAL            using    XV_FILENAME  type STRING
                                         X_HEADER     type FLAG
                                         XV_TAB_NAME  type STRING
                                changing YT_SAP_TABLE type STANDARD TABLE.
                                
"Restituisce un testo standard modificato con input
PERFORM GET_STDTXT              using    XV_STDTXT_NAME type THEAD-TDNAME
                                         XV_LANGUAGE    type TDSPRAS
                                         XT_CONVERTER   type TT_CONVERTER
                                changing YT_STDTXT_OUT  type TT_TLINE

"Restituisce la stringa rimuovendo i caretteri speciali
PERFORM REMOVE_SPECIAL_CHAR     using    XV_CHAR_NOT_REMOVE  type STRING   "Caratteri che von vuoi rimuovere
                                using    X_SPACE             type FLAG     "Mantieni spazio
                                using    X_ALPHA             type FLAG     "Mantieni lettere alfabetiche
                                using    X_NUM               type FLAG     "Mantieni numeri
                                changing YV_STRING_TO_CHANGE type STRING 
                                
"Restituisce un range con i valori del set
PERFORM GET_VALUE_FORM_SET      using    XV_SETNAME type STRING
                                changing YT_RANGE   type TT_HRRANGE.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_HEADER_FROM_DDIC
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_TAB_NAME                    TYPE        STRING
* | [<---] YV_HEADER                      TYPE        STRING
* +-------------------------------------------------------------------------------------------------+
  FORM get_header_from_ddic using    XV_TAB_NAME TYPE STRING
                            changing YV_HEADER   TYPE STRING.
                            
    DATA: lv_details       TYPE abap_compdescr_tab,
          lv_ref_table_des TYPE REF TO cl_abap_structdescr,
          lt_type          TYPE TABLE OF dfies.

    "Prendo i nomi dei campi della tabella
    "-------------------------------------------------
    lv_ref_table_des ?=
        cl_abap_typedescr=>describe_by_name( xv_tab_name ).
    lv_details[] = lv_ref_table_des->components[].

    CHECK lv_details IS NOT INITIAL.

    "Prendo le etichette dei campi della tabella
    "-------------------------------------------------
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = xv_tab_name
        langu          = sy-langu
      TABLES
        dfies_tab      = lt_type
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      "Implement suitable error handling here
    ENDIF.

    "Costruisco l'intestazione
    "-------------------------------------------------
    LOOP AT lt_type ASSIGNING FIELD-SYMBOL(<fieldname>).

      IF yv_header IS INITIAL.
        yv_header = <fieldname>-fieldtext.
      ELSE.
        yv_header = yv_header &&  ';' && <fieldname>-fieldtext.
      ENDIF.

    ENDLOOP.
  ENDFORM.
  
* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>UPLOAD_LOCAL_EXCEL
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_FILENAME                    TYPE        STRING
* | [--->] XV_HEADER                      TYPE        FLAG
* | [<---] YT_FILE_STRING                 TYPE        STRING_TABLE
* +-------------------------------------------------------------------------------------------------+    
FORM upload_local_excel using     XV_FILENAME    TYPE STRING
                                  XV_HEADER      TYPE FLAG
                        changing  YT_FILE_STRING TYPE STRING_TABLE.

    DATA: lv_filename TYPE rlgrap-filename,
          lv_col      TYPE sy-index,
          lv_end_row  TYPE i,
          lv_end_col  TYPE i,
          lv_nfields  TYPE i.
    
    DATA: lv_details       TYPE abap_compdescr_tab,
          lv_ref_table_des TYPE REF TO cl_abap_structdescr,
    
    DATA: lt_intern       TYPE TABLE OF alsmex_tabline,
          lt_intern_index TYPE TABLE OF alsmex_tabline.

    FIELD-SYMBOLS: <intern> LIKE LINE OF lt_intern,
                   <index>  LIKE LINE OF lt_intern,
                   <file>   LIKE LINE OF yt_file_string.

    lv_filename = xv_filename.

    IF lv_filename CS '.xlsx'.

      lv_end_row = 1048576.
      lv_end_col = 16384 .

    ELSEIF lv_filename CS '.xls'.

      lv_end_row = 65536.
      lv_end_col = 256.

    ELSE.
      MESSAGE s646(db) WITH TEXT-e02 DISPLAY LIKE 'E'.
*      STOP.
    ENDIF.

    "-------------------------------------------------
    REFRESH lt_intern[].
    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        filename                = lv_filename
        i_begin_col             = 1
        i_begin_row             = 1
        i_end_col               = lv_end_col
        i_end_row               = lv_end_row
      TABLES
        intern                  = lt_intern[]
      EXCEPTIONS
        inconsistent_parameters = 1
        upload_ole              = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      MESSAGE s646(db) WITH TEXT-e03 DISPLAY LIKE 'E'.
*      STOP.
    ENDIF.

    IF xv_header EQ 'X'.
      DELETE lt_intern WHERE row = 1.
    ENDIF.

    IF lt_intern IS INITIAL.
      MESSAGE s646(db) WITH TEXT-e04 DISPLAY LIKE 'W'.
*      STOP.
    ENDIF.
    
    lv_ref_table_des ?=
        cl_abap_typedescr=>describe_by_name( xv_tab_name ).
    lv_details[] = lv_ref_table_des->components[].
    lv_nfields = lines( lv_details ).
    
    SORT lt_intern BY row col.
    lt_intern_index[] = lt_intern[].
    DELETE ADJACENT DUPLICATES FROM lt_intern_index COMPARING row.

    REFRESH yt_file_string.
    LOOP AT lt_intern_index ASSIGNING <index>.

      APPEND INITIAL LINE TO yt_file_string ASSIGNING <file>.
      DO lv_nfield TIMES.
        lv_col = sy-index.
      
        READ TABLE lt_intern ASSIGNING <intern> BINARY SEARCH
          WITH KEY row = <index>-row
                   col = lv_col.
        IF sy-subrc EQ 0.

          IF <file> IS INITIAL.
            <file> = <intern>-value.
          ELSE.
            <file> = <file> && ';' && <intern>-value.
          ENDIF.
        
        ELSE.
          <file> = <file> && ';' && '$'.
        ENDIF.
        
        REPLACE ALL OCCURRENCES OF '$' IN <file> WITH ' '.
      ENDDO.

    ENDLOOP.
  ENDFORM.
  
* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>UPLOAD_LOCAL_CSV
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_FILENAME                    TYPE        STRING
* | [<---] YT_FILE_STRING                 TYPE        STRING_TABLE
* +-------------------------------------------------------------------------------------------------+  
  FORM upload_local_csv using    XV_FILENAME    TYPE STRING
                        changing YT_FILE_STRING	TYPE STRING_TABLE.

    REFRESH yt_file_string[].
    CALL FUNCTION 'GUI_UPLOAD'
      EXPORTING
        filename                = xv_filename
        filetype                = 'ASC'
      TABLES
        data_tab                = yt_file_string
      EXCEPTIONS
        file_open_error         = 1
        file_read_error         = 2
        no_batch                = 3
        gui_refuse_filetransfer = 4
        invalid_type            = 5
        no_authority            = 6
        unknown_error           = 7
        bad_data_format         = 8
        header_not_allowed      = 9
        separator_not_allowed   = 10
        header_too_long         = 11
        unknown_dp_error        = 12
        access_denied           = 13
        dp_out_of_memory        = 14
        disk_full               = 15
        dp_timeout              = 16
        OTHERS                  = 17.
    IF sy-subrc <> 0.

    ENDIF.

  ENDFORM.
  
* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>HELP_F4_INPUT_DIR
* +-------------------------------------------------------------------------------------------------+
* | [--->] X_OPTION                       TYPE        CHAR1
* | [--->] XV_TITLE                       TYPE        STRING(optional)
* | [<---] YV_DIR                         TYPE        STRING
* +-------------------------------------------------------------------------------------------------+ 
 FORM help_f4_input_dir using X_OPTION  TYPE CHAR1
                              XV_TITLE  TYPE STRING OPTIONAL
                              YV_DIR    TYPE STRING.

    "Ricordati lo user command nei radio button
    CASE x_option.

      WHEN 'L'.

        CALL METHOD cl_gui_frontend_services=>directory_browse
          EXPORTING
            window_title    = xv_title
            initial_folder  = yv_dir
          CHANGING
            selected_folder = yv_dir.

      WHEN 'S'.

        "Selezionre cartella da server
        CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
          EXPORTING
            directory        = yv_dir
            filemask         = '?'
          IMPORTING
            serverfile       = yv_dir
          EXCEPTIONS
            canceled_by_user = 1
            OTHERS           = 2.
        IF sy-subrc <> 0.

        ENDIF.

      WHEN OTHERS.
    ENDCASE.

  ENDFORM. 

* +-------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_LOCAL_DESKTOP_DIR
* +-------------------------------------------------------------------------------------------------+
* | [<---] XV_DIR                         TYPE        STRING
* +-------------------------------------------------------------------------------------------------+
FORM get_local_desktop_dir CHANGING xv_dir.
    CALL METHOD cl_gui_frontend_services=>get_desktop_directory
      CHANGING
        desktop_directory = xv_dir
      EXCEPTIONS
        cntl_error        = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL METHOD cl_gui_cfw=>update_view.
ENDFORM.

* --------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>DISPLAY_GENERIC_ALV
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_TITLE                       TYPE        LVC_TITLE
* | [--->] X_POPUP                        TYPE        CHAR1
* | [<---] XT_TABLE                       TYPE        STANDARD TABLE
* +-------------------------------------------------------------------------------------------------+
  FORM display_generic_alv USING    XV_TITLE type LVC_TITLE
                                    X_POPUP  type CHAR1
                           CHANGING XT_TABLE type STANDARD TABLE..

    DATA: lv_lines TYPE i,
          lv_title TYPE lvc_title.

    DATA: lo_alv            TYPE REF TO cl_salv_table,
          lr_salv_columns   TYPE REF TO cl_salv_columns_table,
          lr_salv_functions TYPE REF TO cl_salv_functions_list,
          lr_salv_dsp_set   TYPE REF TO cl_salv_display_settings,
          lr_salv_events    TYPE REF TO cl_salv_events_table,
          lr_selections     TYPE REF TO cl_salv_selections.

    CLEAR: lv_lines, lv_title.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table   =  lo_alv                    " Basis Class Simple ALV Tables
          CHANGING
            t_table        =  xt_table[]
        ).
      CATCH cx_salv_msg.
    ENDTRY.

    "Set custom menu functions & buttons
    "-------------------------------------------------
    "lo_alv->set_screen_status(
    "   pfstatus      =  'SALV_STANDARD'
    "   report        =  'SALV_DEMO_TABLE_FUNCTIONS'
    "   set_functions = lo_alv->c_functions_all ).

    "Set functions
    "-------------------------------------------------
    lr_salv_functions = lo_alv->get_functions( ).
    lr_salv_functions->set_all( 'X' ). "Lista toolbar standard

    "Set output control
    "-------------------------------------------------
    lr_salv_dsp_set = lo_alv->get_display_settings( ).
    lr_salv_dsp_set->set_striped_pattern( 'X' ).  "Layout zebra

    lv_lines = lines( xt_table[] ).
    lv_title = xv_title && ' (' && lv_lines && ' Record )'.
    lr_salv_dsp_set->set_list_header( lv_title ). "Titolo ALV

    "Set column settings
    "-------------------------------------------------
    lr_salv_columns = lo_alv->get_columns( ).
    lr_salv_columns->set_optimize( 'X' ). "Stringe le colonne

    TRY.
        lr_salv_columns->get_column( 'MANDT' )->set_visible( if_salv_c_bool_sap=>false  ). "Nascondere campi
        lr_salv_columns->get_column( 'NOME_CAMPO' )->set_long_text( 'NEW_NAME' ). "Cambio label
      CATCH cx_salv_not_found.
    ENDTRY.

*    "Implementazione classe per eventi
*    "-------------------------------------------------
*    "----------------------------------------------------------------------*
*    "     CLASS lcl_salv_events DEFINITION                                 *
*    "----------------------------------------------------------------------*
*  CLASS lcl_salv_events DEFINITION.
*    PUBLIC SECTION.
*
*      METHODS:
*        link_click   FOR EVENT link_click   OF cl_salv_events_table
*          IMPORTING row column.
*      METHODS:
*        double_click FOR EVENT double_click OF cl_salv_events_table
*          IMPORTING row column.
*
*  ENDCLASS.                    "lcl_events DEFINITION
*  "----------------------------------------------------------------------*
*  "       CLASS lcl_salv_events IMPLEMENTATION
*  "----------------------------------------------------------------------*
*  "  SAL Event Handler Methods                                           *
*  "----------------------------------------------------------------------*
*  CLASS lcl_salv_events IMPLEMENTATION.
*
*    METHOD link_click.
*
*      FIELD-SYMBOLS: <alv> LIKE LINE OF gt_alv.
*
*      READ TABLE gt_alv ASSIGNING <alv> INDEX row.
*      CHECK sy-subrc EQ 0.
*
*      CASE column.
*        WHEN 'ANLAGE'.
*          SET PARAMETER ID 'ANL' FIELD <alv_0100>-anlage.
*          CALL TRANSACTION 'ES32' AND SKIP FIRST SCREEN.
*
*        WHEN OTHERS.
*      ENDCASE.
*
*    ENDMETHOD.                    "link_click
*
*  ENDCLASS.                    "lcl_events IMPLEMENTATION
*  DATA: gr_salv_event_handler TYPE REF TO lcl_salv_events.

    "lr_salv_events = lo_alv->get_event( ).
    "CREATE OBJECT gr_salv_event_handler.
    "SET HANDLER gr_salv_event_handler->link_click  FOR lr_salv_events.
    "SET HANDLER gr_salv_event_handler->double_click FOR lr_salv_events.

    "Seleziona più righe
    "-------------------------------------------------
    lr_selections = lo_alv->get_selections( ).
    lr_selections->set_selection_mode( if_salv_c_selection_mode=>row_column ).

    "Set alv in pop_up mode
    "-------------------------------------------------
    IF x_popup EQ 'X'.

      lo_alv->set_screen_popup(
              start_column = 1
              end_column   = 100
              start_line   = 1
              end_line     = 15 ).

    ENDIF.

    "Output the table
    "-------------------------------------------------
    lo_alv->display( ).

  ENDFORM.
  
* --------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_TRANSPOSED_TABLE
* +-------------------------------------------------------------------------------------------------+
* | [<---] YO_DATA_TRANSP                 TYPE        DATA
* | [<---] YT_FCAT_TRANSP                 TYPE        LVC_T_FCAT
* | [<-->] XT_TABLE                       TYPE        STANDARD TABLE
* +-------------------------------------------------------------------------------------------------+
  METHOD get_transposed_table CHANGING YO_DATA_TRANSP type DATA
                                       YT_FCAT_TRANSP type LVC_T_FCAT
                                       XT_TABLE       type STANDARD TABLE..

**********************************************************************
*     ESEMPIO DI LANCIO
*
*    SELECT * UP TO 1 ROWS
*     FROM sflight INTO TABLE @DATA(lt_my_table).
*
*    DATA: lo_data_transp TYPE REF TO data.
*
*    zag_cl_utils=>get_transposed_table(
*      IMPORTING
*        yo_data_transp = lo_data_transp
*      CHANGING
*        xt_table       = lt_my_table
*    ).
*
*    ASSIGN lo_data_transp->* TO FIELD-SYMBOL(<transposed>).
*
*
*    zag_cl_utils=>display_generic_alv(
*      EXPORTING
*        x_popup   = abap_true
*      CHANGING
*        xt_table  = <transposed>
*    ).
**********************************************************************

    DATA: lt_fcat   TYPE lvc_t_fcat,
          lo_transp TYPE REF TO data.

    FIELD-SYMBOLS: <fcat>           TYPE lvc_s_fcat,
                   <lt_transp_data> TYPE table,
                   <yt_data_transp> TYPE table.

    "-------------------------------------------------

    CLEAR: yo_data_transp, yt_fcat_transp[].

    CHECK lines( xt_table ) EQ 1.

    "------------------------------------------------
    "-> Creazione tabella 'DESCR_CAMPO' + 'VALORE'
    "-> con relativo riferimento <fs>

    APPEND INITIAL LINE TO lt_fcat ASSIGNING <fcat>.
    <fcat>-fieldname  = 'COLUMNTEXT'.
    <fcat>-ref_table  = 'LVC_S_DETA'.

    APPEND INITIAL LINE TO lt_fcat ASSIGNING <fcat>.
    <fcat>-fieldname  = 'VALUE'.
    <fcat>-ref_field  = 'VALUE'.
    <fcat>-ref_table  = 'LVC_S_DETA'.

    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog = lt_fcat
      IMPORTING
        ep_table        = lo_transp.

    ASSIGN lo_transp->* TO <lt_transp_data>.


    "------------------------------------------------
    "-> Estrazione lista campi tabella originale

    DATA: lo_alv        TYPE REF TO cl_salv_table,
          lr_columns    TYPE REF TO cl_salv_columns_table,
          lt_column_ref TYPE salv_t_column_ref.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = xt_table[] ).

      CATCH cx_salv_msg.
    ENDTRY.

    lr_columns    = lo_alv->get_columns( ).
    lt_column_ref = lr_columns->get( ).


    "------------------------------------------------
    "-> Trasposizione campi da NxM a MxN

    READ TABLE xt_table ASSIGNING FIELD-SYMBOL(<original_row>) INDEX 1.

    LOOP AT lt_column_ref ASSIGNING FIELD-SYMBOL(<column_ref>).

      CHECK <column_ref>-columnname NE 'MANDT'.

      ASSIGN COMPONENT <column_ref>-columnname OF STRUCTURE <original_row> TO FIELD-SYMBOL(<original_value>).
      CHECK sy-subrc EQ 0.

      APPEND INITIAL LINE TO <lt_transp_data> ASSIGNING FIELD-SYMBOL(<transp_row>).

      ASSIGN COMPONENT 'COLUMNTEXT' OF STRUCTURE <transp_row> TO FIELD-SYMBOL(<transp_coltxt>).
      ASSIGN COMPONENT 'VALUE'      OF STRUCTURE <transp_row> TO FIELD-SYMBOL(<transp_value>).

      <transp_coltxt> = <column_ref>-r_column->get_long_text( ).
      <transp_value>  = <original_value>.

    ENDLOOP.

    "------------------------------------------------
    "-> Esportazione tabella esportata

    CALL METHOD cl_alv_table_create=>create_dynamic_table
      EXPORTING
        it_fieldcatalog = lt_fcat
      IMPORTING
        ep_table        = yo_data_transp.

    ASSIGN yo_data_transp->* TO <yt_data_transp>.
    <yt_data_transp> = <lt_transp_data>.

  ENDFORM.

* --------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>UPLOAD_LOCAL
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_FILENAME              TYPE        STRING
* | [--->] X_HEADER                 TYPE        FLAG
* | [--->] XV_TAB_NAME              TYPE        STRING
* | [<---] YT_SAP_TABLE             TYPE        STABDARD TABLE
* +-------------------------------------------------------------------------------------------------+
  FORM upload_local USING    XV_FILENAME  type STRING
                             X_HEADER     type FLAG
                             XV_TAB_NAME  type STRING
                    CHANGING YT_SAP_TABLE type STANDARD TABLE..

    CONSTANTS: lc_data_base TYPE string VALUE '00000000'.

    DATA: lv_filename TYPE string,
          lv_stringa  TYPE string,
          lv_stringa2 TYPE string,
          lv_dato     TYPE string.

    DATA: lv_sap_ref TYPE REF TO data.

    DATA: lv_field_list    TYPE abap_compdescr_tab,
          lo_ref_table_des TYPE REF TO cl_abap_structdescr.

    DATA: lt_string TYPE TABLE OF string.

    FIELD-SYMBOLS: <sap_tb> TYPE any,
                   <field>  LIKE LINE OF lv_field_list,
                   <string> TYPE string,
                   <out>    TYPE any.

    REFRESH lt_string.
    IF xv_filename CP '*.xls'
      OR xv_filename CP '*.xlsx'.
      
        PERFORM upload_local_excel USING    xv_filename     " Percorso file
                                            x_header        " Presenza dell'intestazione
                                   CHANGING lt_string.      " Tabella stringhe
        
    ELSEIF xv_filename CP '*.csv'.
    
      PERFORM upload_local_csv USING    xv_filename " Path file di input
                               CHANGING lt_string.  " Tabella stringhe

    ENDIF.


    lo_ref_table_des ?=
          cl_abap_typedescr=>describe_by_name( xv_tab_name ).
    lv_field_list[] = lo_ref_table_des->components[].
    CHECK lv_field_list IS NOT INITIAL.

    CREATE DATA lv_sap_ref TYPE REF TO (xv_tab_name).
    ASSIGN lv_sap_ref->* TO <sap_tb>.

    LOOP AT lt_string ASSIGNING <string>.

      APPEND INITIAL LINE TO yt_sap_table ASSIGNING <sap_tb>.

      CLEAR lv_stringa.
      CLEAR lv_stringa2.
      LOOP AT lv_field_list ASSIGNING <field>.

        ASSIGN COMPONENT <field>-name OF STRUCTURE <sap_tb> TO <out>.
        CHECK sy-subrc EQ 0.

        CLEAR lv_dato.

        IF lv_stringa IS INITIAL.
          lv_stringa = <string>.
        ELSE.
          lv_stringa = lv_stringa2.
        ENDIF.

        SPLIT lv_stringa AT ';' INTO lv_dato lv_stringa2.

        CASE <field>-type_kind.
          WHEN cl_abap_typedescr=>typekind_float.

          WHEN cl_abap_typedescr=>typekind_date.

*            IF <field>-name EQ 'NOME_CAMPO_DATA'
*              OR <field>-name EQ 'NOME_CAMPO_DATA'.
*              IF strlen( lv_dato ) EQ 10.
*                <out> = lv_dato+6(4) && lv_dato+3(2) && lv_dato(2).
*              ELSE.
*                <out> = lc_data_base.
*              ENDIF.
*            ENDIF.

          WHEN OTHERS.
            <out> = lv_dato.
        ENDCASE.

      ENDLOOP.

    ENDLOOP.

  ENDFORM.
  
* --------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_STDTXT
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_STDTXT_NAME           TYPE        THEAD-TDNAME
* | [--->] XV_LANGUAGE              TYPE        TDSPRAS
* | [--->] XT_CONVERTER             TYPE        TT_CONVERTER
* | [<---] YT_STDTXT_OUT            TYPE        TT_TLINE
* +-------------------------------------------------------------------------------------------------+
  FORM get_stdtxt USING    XV_STDTXT_NAME type THEAD-TDNAME
                           XV_LANGUAGE    type TDSPRAS
                           XT_CONVERTER   type TT_CONVERTER
                  CHANGING YT_STDTXT_OUT  type TT_TLINE.
                  
    TYPES:
       BEGIN OF ty_converter,
          field TYPE string,
          value TYPE string,
        END OF ty_converter .

    TYPES:
      tt_tline TYPE TABLE OF tline .
    TYPES:
      tt_converter TYPE TABLE OF ty_converter .
      
    FIELD-SYMBOLS: <conv> LIKE LINE OF xt_converter,
                   <out>  LIKE LINE OF yt_stdtxt_out.

    REFRESH yt_stdtxt_out[].

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
*       CLIENT                  = SY-MANDT
        id                      = 'ST'
        language                = xv_language
        name                    = xv_stdtxt_name
        object                  = 'TEXT'
      TABLES
        lines                   = yt_stdtxt_out[]
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    LOOP AT yt_stdtxt_out ASSIGNING <out>.

      LOOP AT xt_converter ASSIGNING <conv>.
        REPLACE ALL OCCURRENCES OF <conv>-field IN <out>-tdline WITH <conv>-value.
      ENDLOOP.

    ENDLOOP.

  ENDFORM.

* --------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>REMOVE_SPECIAL_CHAR
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_CHAR_NOT_REMOVE       TYPE        STRING
* | [--->] X_SPACE                  TYPE        FLAG
* | [--->] X_ALPHA                  TYPE        FLAG
* | [--->] X_NUM                    TYPE        FLAG
* | [<---] YV_STRING_TO_CHANGE      TYPE        STRING
* +-------------------------------------------------------------------------------------------------+
  FORM remove_special_char  USING    XV_CHAR_NOT_REMOVE   type STRING   "Caratteri che von vuoi rimuovere
                            USING    X_SPACE             type FLAG     "Mantieni spazio
                            USING    X_ALPHA             type FLAG     "Mantieni lettere alfabetiche
                            USING    X_NUM               type FLAG     "Mantieni numeri
                            CHANGING YV_STRING_TO_CHANGE type STRING.
                            
    "~`!@#$%^&*()-_+={}[]|\/:;"'<>,.? all special char
    DATA: lv_char      TYPE char1,
          lv_regex_fix TYPE string VALUE '[^',
          lv_regex_adt TYPE string,
          lv_cont      TYPE sy-index.

    IF xv_char_not_remove IS NOT INITIAL
      OR x_space IS NOT INITIAL
      OR x_num   IS NOT INITIAL
      OR x_alpha IS NOT INITIAL.

      CLEAR lv_regex_adt.
      DO strlen( xv_char_not_remove ) TIMES.
        CLEAR lv_char.
        lv_cont = sy-index - 1.
        lv_char = xv_char_not_remove+lv_cont(1).
        CHECK NOT lv_regex_adt CA lv_char.
        IF lv_regex_adt IS INITIAL.
          lv_regex_adt = '\' && lv_char.
        ELSE.
          lv_regex_adt = lv_regex_adt && '\' && lv_char.
        ENDIF.
      ENDDO.

      "Non rimuovo le lettere
      IF x_alpha IS NOT INITIAL.
        lv_regex_fix = lv_regex_fix && '[:alpha:]'.
      ENDIF.

      "Non rimuovo lo spazio
      IF x_space IS NOT INITIAL.
        lv_regex_fix = lv_regex_fix && '\s'.
      ENDIF.

      "Non rimuovo i numeri
      IF x_num IS NOT INITIAL.
        lv_regex_fix = lv_regex_fix && '\d'.
      ENDIF.

      lv_regex_fix = lv_regex_fix && lv_regex_adt && ']'.

      REPLACE ALL OCCURRENCES OF REGEX lv_regex_fix IN yv_string_to_change WITH ''.

    ENDIF.

  ENDFORM.
  
* --------------------------------------------------------------------------------------------------+
* | Static Public Method ZMS_CL_UTILITIES=>GET_VALUE_FROM_SET
* +-------------------------------------------------------------------------------------------------+
* | [--->] XV_SETNAME      TYPE        STRING
* | [<---] YT_RANGE        TYPE        TT_HRRANGE
* +-------------------------------------------------------------------------------------------------+
  FORM get_value_from_set USING    XV_SETNAME type STRING
                          CHANGING YT_RANGE   type TT_HRRANGE.
                          
  TYPES: tt_harrange TYPE TABLE OF harrange.
  
  DATA: lv_idset     TYPE sethier-setid,
        lt_setvalues TYPE STANDARD TABLE OF rgsbv,
        lv_setname   TYPE c LENGTH 24.

  REFRESH yt_range[].

  lv_setname = xv_setname.
  CONDENSE lv_setname NO-GAPS.

  "Dato il nome del set restituisce l'id del set
  "-------------------------------------------------
  CLEAR lv_idset.
  CALL FUNCTION 'G_SET_GET_ID_FROM_NAME'
    EXPORTING
      shortname = lv_setname       "Set Name
    IMPORTING
      new_setid = lv_idset
    EXCEPTIONS
      OTHERS    = 1.

  CHECK sy-subrc EQ 0.

  "Dato l'id del set restituisce i valori del set
  "-------------------------------------------------
  REFRESH lt_setvalues[].
  CALL FUNCTION 'G_SET_FETCH'
    EXPORTING
      setnr           = lv_idset
    TABLES
      set_lines_basic = lt_setvalues[]
    EXCEPTIONS
      OTHERS          = 1.

  CHECK lt_setvalues[] IS NOT INITIAL.

  "Costruisco il range con i valori precedentemente ottenuti
  "-------------------------------------------------
  yt_range = VALUE #( FOR <range> IN lt_setvalues ( sign = 'I'           opti = 'BT'
                                                    low  = <range>-from  high = <range>-to ) ).

 ENDFORM.
