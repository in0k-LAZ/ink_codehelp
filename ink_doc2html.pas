unit ink_doc2html;

{$mode objfpc}{$H+}

interface

uses RegExpr, sysutils, strutils;

function inkDoc_2_HTML(const sourceText:string; out inkDoc_Pos,inkDoc_len:integer; out htmlText:string):boolean;

implementation

{%region 'формирование HTML'                                      /fold}

function _iD2HTML_2html_Title(const Text:string):string;
begin
    result:='<div class="title"><font style="font-size:87%">'+Text+'</font></div>';
end;

function _iD2HTML_2html_descroption(const Text:string):string;
begin
    result:=Text+'<br>';
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function _iD2HTML_2html_TABLE_name(const txt,color:string):string;
begin
    result:='';
    result:=result+'<tr><td colspan=3 align="left"><div class="title"><font style="font-size: 25%;">&nbsp;</font></div></td></tr>';
    result:=result+'<tr><td colspan=3 align="left"><div class="title"><font style="font-size: 75%; color:'+color+';">'+(txt)+'</font></div></td></tr>';
end;

function _iD2HTML_2html_TABLE_note(const txt:string):string;
begin
    result:='<tr><td width=1>&nbsp;&nbsp;</td><td colspan=2 align="left">'+trim(txt)+'</td></tr>';
end;

function _iD2HTML_2html_TABLE_row(const ind,txt:string):string;
begin
    result:='<tr><td width=1>&nbsp;&nbsp;</td><td align="left" width=1><span class="identifier">'+trim(ind)+'</span>&nbsp;</td><td align="left">'+trim(txt)+'</td></tr>';
end;

function _iD2HTML_2html_TABLE(const txt:string):string;
begin
    result:='<table border=0 cellpadding=0 cellspacing=0>'+txt+'</table><br>';
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function _iD2HTML_2html_comment(const Text:string):string;
begin
    result:=_iD2HTML_2html_TABLE(_iD2HTML_2html_TABLE_name('дополнительно','gray'));
    result:=result+'<span class="comment" style="font-size:85%">'+Text+'</span>';
end;

{%endregion}

{%region 'ПАРСИНГ исходного текста'                               /fold}

var
 _RE_:TRegExpr;

const
  cToken_incDoc_B  ='inkDoc>'; //< Begin
  cToken_incDoc_E  ='<inkDoc'; //< End

  cToken_incDoc_prm='prm'; //< Название - Описание
  cToken_incDoc_ret='ret'; //< Название - Описание
  cToken_incDoc_exc='exc'; //< Название - Описание

  cToken_forGroup  =':';
  cToken_otherVAL  ='~';
  cToken_anySMBs   ='(.*?)';
  cToken_skbSMBs   ='\('+cToken_anySMBs+'\)';
  cBodyTokens=cToken_incDoc_prm+'|'+cToken_incDoc_ret+'|'+cToken_incDoc_exc;


//------------------------------------------------------------------------------

{incDoc>разбор и формирование "Заголовка"                                <
    @prm(RegExpr    работа с регулярными выражениями)
    @prm(sourceText текст для разбора)
    @prm(htmlText   результат разбра в "формате" HTML)
    @ret(false      критическая ошибка, дальнейшая работа ДОЛЖНА быть прекращена)
<incDoc}
function _iD2HTML_parce_Title(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
begin
    result:=true;
    //---
    htmlText:=trim(sourceText);
    if htmlText<>'' then htmlText:=_iD2HTML_2html_Title(htmlText);
end;

function _iD2HTML_parce_Description(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
begin
    result:=true;
    //---
    htmlText:=trim(sourceText);
    if htmlText<>'' then htmlText:=_iD2HTML_2html_descroption(htmlText);
end;

function _iD2HTML_parce_table_Note(const RegExpr:TRegExpr; const sourceText,Token:string; out htmlText:string):boolean;
begin
    result:=true;
    htmlText:='';
    //---
    RegExpr.InputString:=sourceText;
    RegExpr.Expression:='@'+Token+'\(\s?'+cToken_forGroup+'\s?(.*?)\)';
    if RegExpr.ExecPos(1) then begin
        htmlText:=trim(RegExpr.Match[1]);
        if htmlText<>'' then htmlText:=_iD2HTML_2html_TABLE_note(htmlText)
    end;
end;

function _iD2HTML_parce_table_Rows(const RegExpr:TRegExpr; const sourceText,Token:string; out htmlText:string):boolean;
begin
    result:=true;
    htmlText:='';
    //---
    RegExpr.InputString:=sourceText;
    RegExpr.Expression:='@'+Token+'\(\s?([^('+cToken_forGroup+'\s?)].*?)\s(.*?)\)';
    if RegExpr.ExecPos(1) then begin
        htmlText:=htmlText+_iD2HTML_2html_TABLE_row(RegExpr.Match[1],RegExpr.Match[2]);
        while RegExpr.ExecNext do begin
            htmlText:=htmlText+_iD2HTML_2html_TABLE_row(RegExpr.Match[1],RegExpr.Match[2]);
        end;
    end;
end;

function _iD2HTML_tablePRMs(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
var tmp_Html:string;
begin
    result:=true;
    htmlText:='';
    //---
    if result and _iD2HTML_parce_table_Note(RegExpr,sourceText,cToken_incDoc_prm,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if result and _iD2HTML_parce_table_Rows(RegExpr,sourceText,cToken_incDoc_prm,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if htmlText<>'' then begin
        htmlText:=_iD2HTML_2html_TABLE_name('параметры','darkblue')+htmlText;
        htmlText:=_iD2HTML_2html_TABLE(htmlText);
    end;
end;

function _iD2HTML_tableRETs(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
var tmp_Html:string;
begin
    result:=true;
    htmlText:='';
    //---
    if result and _iD2HTML_parce_table_Note(RegExpr,sourceText,cToken_incDoc_ret,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if result and _iD2HTML_parce_table_Rows(RegExpr,sourceText,cToken_incDoc_ret,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if htmlText<>'' then begin
        htmlText:=_iD2HTML_2html_TABLE_name('результат','darkgren')+htmlText;
        htmlText:=_iD2HTML_2html_TABLE(htmlText);
    end;
end;

function _iD2HTML_tableEXCs(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
var tmp_Html:string;
begin
    result:=true;
    htmlText:='';
    //---
    if result and _iD2HTML_parce_table_Note(RegExpr,sourceText,cToken_incDoc_exc,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if result and _iD2HTML_parce_table_Rows(RegExpr,sourceText,cToken_incDoc_exc,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if htmlText<>'' then begin
        htmlText:=_iD2HTML_2html_TABLE_name('исключения','darkred')+htmlText;
        htmlText:=_iD2HTML_2html_TABLE(htmlText);
    end;
end;

function _iD2HTML_TABLEs(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
var tmp_Html:string;
begin
    result:=true;
    htmlText:='';
    //---
    if result and _iD2HTML_tablePRMs(RegExpr,sourceText,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if result and _iD2HTML_tableRETs(RegExpr,sourceText,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
    if result and _iD2HTML_tableEXCs(RegExpr,sourceText,tmp_html) then begin
        htmlText:=htmlText+tmp_html;
    end;
end;

function _iD2HTML_COMMENT(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
var tmp_Html:string;
begin
    result:=true;
    //---
    htmlText:=trim(sourceText);
    if htmlText<>'' then htmlText:=_iD2HTML_2html_comment(htmlText)
end;

function _iD2HTML_BODY(const RegExpr:TRegExpr; const sourceText:string; out htmlText:string):boolean;
var tmp_Html:string;
    tmp_text:string;
    tmp_last:integer;
begin
    result:=true;
    htmlText:='';
    //---
    RegExpr.InputString:=sourceText;
    RegExpr.Expression:=cToken_anySMBs+'(@('+cBodyTokens+')'+cToken_skbSMBs+')';
    if RegExpr.ExecPos(1) then begin
        tmp_last:=RegExpr.MatchPos[2]+RegExpr.MatchLen[2];
        tmp_text:=RegExpr.Match[2];
        //--- описание
        if result and _iD2HTML_parce_Description(RegExpr,RegExpr.Match[1],tmp_html) then begin
            htmlText:=htmlText+tmp_html;
        end;
        //--- тело TABLICI
        if result then begin //< собираем в кучу
            while RegExpr.ExecNext do begin
                tmp_text:=tmp_text+RegExpr.Match[2];
                tmp_last:=RegExpr.MatchPos[2]+RegExpr.MatchLen[2];
            end;
        end;
        if result and _iD2HTML_TABLEs(RegExpr,tmp_text,tmp_html) then begin
            htmlText:=htmlText+tmp_html;
        end;
        //--- комментарий
        if result then begin
            tmp_text:=copy(sourceText,tmp_last,length(sourceText)-tmp_last);
        end;
        if result and _iD2HTML_COMMENT(RegExpr,tmp_text,tmp_html) then begin
            htmlText:=htmlText+tmp_html;
        end;
    end;
end;

//---

function _iD2HTML_(const RegExpr:TRegExpr; const sourceText:string; out inkDoc_Pos,inkDoc_len:integer; out htmlText:string):boolean;
var tmp_title:string;
    tmp_Body :string;
    tmp_html :string;
begin
    result:=false;
    //---
    RegExpr.InputString:=sourceText;
    RegExpr.Expression:=
        cToken_incDoc_B     + //< начальный тег
        cToken_anySMBs+'(\s\S|\s\S\s+)?$'  + //< заголовок (первая строка сразу за начальным тегом)
        cToken_anySMBs      + //< весь остальной текст
        cToken_incDoc_E;      //< конечный тег
    //---
    if  RegExpr.ExecPos(1) then begin
        result:=true;
        inkDoc_Pos:=RegExpr.MatchPos[0];
        inkDoc_len:=RegExpr.MatchLen[0];
        //---
        tmp_title:=RegExpr.Match[1];
        tmp_Body :=RegExpr.Match[3];
        if result and _iD2HTML_parce_Title(RegExpr,tmp_title,tmp_html) then begin
            htmlText:=htmlText+tmp_html;
        end;
        if result and _iD2HTML_BODY(RegExpr,tmp_Body,tmp_html) then begin
            htmlText:=htmlText+tmp_html;
        end;
    end
    else result:=false;
    //---
    if not result then begin
        inkDoc_Pos:=0;
        inkDoc_len:=0;
        htmlText  :='';
    end
    else begin
        htmlText:='<table border=0><tr><td>&nbsp&nbsp</td><td>'+htmlText+'</td></tr></table>'
    end;
end;

{%endregion}

{inkDoc>текст "Hint from Comment" преобразовать в "формат" HTML        <
    парсим текст по средством регулярных выражений
    @prm(sourceText исходный текст в котором пытаемся найти НАШ формат)
    @prm(inkDoc_Pos начальная позиция найденного фрагмента)
    @prm(inkDoc_len длинна найденного фрагмента)
    @prm(htmlText   результат работы функции в формате HTML)
    @ret(false критическая ошибка, НИЧЕГО не смогли поделать, или этотого фрагмента нет)
    не совсем аккуратное (в смысле кода и кода html). и вооббще, надо сделать
    нормальный парсинг и синтактическим деревом для отлова вложенных скобок.
<inkDoc}
function inkDoc_2_HTML(const sourceText:string; out inkDoc_Pos,inkDoc_len:integer; out htmlText:string):boolean;
begin
    result:=_iD2HTML_(_RE_, sourceText,inkDoc_Pos,inkDoc_len,htmlText);
end;

initialization
    _RE_:=TRegExpr.Create;
    _RE_.ModifierM:=true;
    _RE_.ModifierI:=true;
finalization
    _RE_.Free;
    _RE_:=nil
end.

