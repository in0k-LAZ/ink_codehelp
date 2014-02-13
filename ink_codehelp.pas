unit ink_codehelp;

{$mode objfpc}{$H+}

{off $DEFINE VerboseCodeHelp}
{off $DEFINE VerboseCodeHelpFails}
{off $DEFINE VerboseHints}

{$IFDEF VerboseCodeHelp}
  {$DEFINE VerboseCodeHelpFails}
{$ENDIF}


{.$define ink_codehelp_DEBUG}

interface

uses RegExpr, ink_doc2html,
  Classes, CodeTree, FindDeclarationTool, BasicCodeTools, CodeCache, CodeHelp, PascalParserTool, sysutils;

type

  TinkCodeHelpManager = class(TCodeHelpManager)
  protected
    function _ink_getComment(const Tool: TFindDeclarationTool; const Node:TCodeTreeNode):string;
    function _ink_getComments(const Tool:TFindDeclarationTool; const NodeInterface,NodeImplementation:TCodeTreeNode):string;
    function _inc_getNodePlace(const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):TCodeTreeNodeDesc;
  public
    function GetPasDocCommentsAsHTML(Tool:TFindDeclarationTool; Node:TCodeTreeNode):string; override;
    function PasDocCommentsToHTML(const srcText:string):string;
  end;


implementation

{найти и сформировать строку HintFromComment для узла. ворованно из пародителя}
function TinkCodeHelpManager._ink_getComment(const Tool: TFindDeclarationTool; const Node:TCodeTreeNode):string;
var ListOfPCodeXYPosition: TFPList;
    NestedComments: Boolean;
    i: Integer;
    CommentCode: TCodeBuffer;
    CommentStart: integer;
    CodeXYPos: PCodeXYPosition;
    CommentStr: String;
begin
    try
        result:='';
        if not Tool.GetPasDocComments(Node,ListOfPCodeXYPosition) then exit;
        if ListOfPCodeXYPosition=nil then exit;
        NestedComments := Tool.Scanner.NestedComments;
        //---
        for i:= 0 to ListOfPCodeXYPosition.Count - 1 do begin
            CodeXYPos := PCodeXYPosition(ListOfPCodeXYPosition[i]);
            CommentCode := CodeXYPos^.Code;
            CommentCode.LineColToPosition(CodeXYPos^.Y,CodeXYPos^.X,CommentStart);
            if (CommentStart<1) or (CommentStart>CommentCode.SourceLength) then continue;
            Result:=Result+ExtractCommentContent(CommentCode.Source,CommentStart,
                                         NestedComments,true,true,true)+LineEnding;
        end;
    finally
        FreeListOfPCodeXYPosition(ListOfPCodeXYPosition);
    end;
end;

function TinkCodeHelpManager.PasDocCommentsToHTML(const srcText:string):string;
var i,j:integer;
tmpText:string;
begin
    result:='';
    //---
    if ink_doc2html.inkDoc_2_HTML(srcText,j,i,tmpText) then begin
        result :=tmpText;
        tmpText:=srcText;
        delete(tmpText,j,i);
    end
    else begin
        tmpText:=srcText;
    end;
    //---
    if tmpText<>'' then begin
        if result<>'' then result:=result+'<br>';
        result:=result+'<span class="comment">'+TextToHTML(tmpText)+'</span>';
    end;
    //---
    if result<>'' then result:=result+LineEnding;
end;


{ найти и сформировать строку HintFromComment для узлов из раздела Interface и Implementation}
function TinkCodeHelpManager._ink_getComments(const Tool:TFindDeclarationTool; const NodeInterface,NodeImplementation:TCodeTreeNode):string;
begin
    {$ifDef ink_codehelp_DEBUG}
      result:='_ink_getComments';
      result:=result+LineEnding;
      result:=result+'NodeInterface=';
      if NodeInterface<>nil then result:=result+inttostr(NodeInterface.StartPos)
                            else result:=result+'nil';

      result:=result+LineEnding;
      result:=result+'NodeImplementation='+inttostr(NodeImplementation.StartPos);
      if NodeImplementation<>nil then result:=result+inttostr(NodeImplementation.StartPos)
                                 else result:=result+'nil';
      result:=result+ LineEnding;
    {$endIf}
    result:='';
    if NodeInterface     <>nil then result:=result+_ink_getComment(Tool,NodeInterface);
    if NodeImplementation<>nil then result:=result+_ink_getComment(Tool,NodeImplementation);
    //--- а вот тут, наверно, можно попробовать "распарсить" pasDoc или аналоги
    // что мы и делаем
    if Result<>'' then Result:=PasDocCommentsToHTML(Result)+LineEnding;
end;

{ определить местоположение Узла в разделах Модуля }
function TinkCodeHelpManager._inc_getNodePlace(const Tool:TFindDeclarationTool; const Node:TCodeTreeNode):TCodeTreeNodeDesc;
begin
    result:=ctnNone;
    if tool.NodeHasParentOfType(Node,ctnInterface) then result:=ctnInterface
   else
    if tool.NodeHasParentOfType(Node,ctnImplementation) then result:=ctnImplementation
end;

function TinkCodeHelpManager.GetPasDocCommentsAsHTML(Tool: TFindDeclarationTool; Node: TCodeTreeNode): string;
const //< из всего богатства выбора ... выбираем
    ProcAttr = [
    //phpWithStart,          // proc keyword e.g. 'function', 'class procedure'
    //phpWithoutClassKeyword,// without 'class' proc keyword
    phpAddClassName,       // extract/add 'ClassName.'
    //phpWithoutClassName,   // skip classname
    //phpWithoutName,        // skip function name
    //phpWithoutParamList,   // skip param list
    phpWithVarModifiers,   // extract 'var', 'out', 'const'
    phpWithParameterNames, // extract parameter names
    phpWithoutParamTypes,  // skip colon, param types and default values
    //phpWithHasDefaultValues,// extract the equal sign of default values
    phpWithDefaultValues,  // extract default values
    //phpWithResultType,     // extract colon + result type
    //phpWithOfObject,       // extract 'of object'
    //phpWithCallingSpecs,   // extract cdecl; extdecl; popstack;
    //phpWithProcModifiers,  // extract forward; alias; external; ...
    //phpWithComments,       // extract comments and spaces
    phpInUpperCase        // turn to uppercase
    //phpCommentsToSpace,    // replace comments with a single space
                           //  (default is to skip unnecessary space,
                           //    e.g 'Do   ;' normally becomes 'Do;'
                           //    with this option you get 'Do ;')
    //phpWithoutBrackets,    // skip start- and end-bracket of parameter list
    //phpWithoutSemicolon,   // skip semicolon at end
    //phpDoNotAddSemicolon,  // do not add missing semicolon at end
    // search attributes:
    //phpIgnoreForwards     // skip forward procs
    //hpIgnoreProcsWithBody,// skip procs with begin..end
    //phpIgnoreMethods,      // skip method bodies and definitions
    //phpOnlyWithClassname,  // skip procs without the right classname
    // phpFindCleanPosition,  // read til ExtractSearchPos
    // parse attributes:
    //phpCreateNodes         // create nodes during reading
    ];
begin
    Result:='';
    if (Tool=nil)or(Node=nil) then exit;
    if not(node.Desc in [ctnProcedure,ctnProcedureHead])
    then begin
        {$ifDef ink_codehelp_DEBUG}
          result:='inherited GetPasDocCommentsAsHTML';
          result:=result+ LineEnding;
        {$endIf}
        // тут все вопросы к Папе, он за нас ответит.
        result:=result+inherited GetPasDocCommentsAsHTML(Tool,Node);
    end
    else begin
         if Node.Desc=ctnProcedureHead then Node:=Node.Parent;
         //---
         {$ifDef ink_codehelp_DEBUG}
           result:='ProcHead:'+Tool.ExtractProcHead(Node,ProcAttr);
           result:=result+ LineEnding;
         {$endIf}
         case _inc_getNodePlace(Tool,node) of
           ctnInterface:   // Tool.FindDeclaration();
                result:=result+_ink_getComments(Tool,node,Tool.FindCorrespondingProcNode(node,ProcAttr));
           ctnImplementation:
                result:=result+_ink_getComments(Tool,Tool.FindCorrespondingProcNode(node,ProcAttr),node);
           else begin //< к ТАКОМУ повороту мы не готовы, попросим Папу
                result:=inherited GetPasDocCommentsAsHTML(Tool,Node);
           end
         end;
    end;
end;

end.

