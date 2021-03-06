#Include <Scintilla>
#Include ..\_INCLUDE\_LibraryV2\TheArkive_Debug.ahk
#Include ..\_INCLUDE\_LibraryV2\_JXON.ahk

global main, dllHwnd := 0

main := Gui.New()
main.OnEvent("Close","guiClose")
; main.MarginX := main.MarginY := 0
addBtn := main.addButton("section vAddDoc", "Add New")
addBtn.OnEvent("click", "AddNewDoc")
main.addButton("ys Disabled vDeleteDoc", "Delete").OnEvent("click", "deleteDoc")
addBtn.GetPos(,,,h)
main.addText("ys w1 h" h + 2 " 0x11")
main.addButton("ys Disabled vPrevDoc", "Previous").OnEvent("click","changeDoc")
main.addButton("ys Disabled vNextDoc", "Next").OnEvent("click", "changeDoc")
main.addButton("ys x+400 vSplitDoc", "Split Doc").OnEvent("click", "splitDoc")
main.addButton("ys Disabled vUnsplitDoc", "Unsplit Doc").OnEvent("click", "unsplitDoc")

global sciDocs := [] ; store doc pointers
global currentDoc := 0

currentDoc++
global sci := Scintilla.New(main, "w800 h400 xs Section vEdit", , 0, 0)
sciDocs.push(sci.GetDocPointer()) ; store the initial doc pointer
setupSciControl(sci)

sci.OnNotify(sci.SCN_DOUBLECLICK, "showCurrentSelection") ; listen for events
sci.OnNotify(sci.SCN_STYLENEEDED, "styleNeeded")

sci.ctrl.GetPos(x,y,w,h), pos := {x:x, y:y, w:w, h:h}
global sci2 := Scintilla.New(main, "yp xp+" (pos.w) // 2 " w0 h400 Hidden vEdit2", , 0, 0)
setupSciControl(sci2) ; apply generic styling

main.Show()

return

styleNeeded(sci, lParam, notifyCode) {
    ; lastStyle := sci.GetEndStyled() ; example from: http://sphere.sourceforge.net/flik/docs/scintilla-container_lexer.html
    ; lineCount := sci.GetLineCount()
    ; curLine := sci.LineFromPosition(lastStyle)
    ; startPos := sci.PositionFromLine(curLine)
    ; endPos := sci.Position
    ; lineLen := sci.LineLength(curLine)
    
    ; i := 0
    ; if (lineLen > 0) {
        ; firstChar := Chr(sci.GetCharAt(startPos))
        
        ; sci.StartStyling(startPos) ; important!
        
        ; Switch firstChar
        ; {
            ; case "-": sci.SetStyling(lineLen,sci.RED_STYLE)
            ; case "/": sci.SetStyling(lineLen,sci.ORANGE_STYLE)
        ; }
        ; i++
    ; }
    
    
    
    lastStyle := sci.GetEndStyled() ; my example, does thie full document
    lineCount := sci.GetLineCount()
    i := 0 ; this chunk works pretty fast
    While (i <= lineCount) {
        curLine := "X"
        startPos := sci.PositionFromLine(i)
        
        lineLen := sci.LineLength(i)
        endPos := startPos + lineLen - 1
        
        firstChar := Chr(sci.GetCharAt(startPos))
        
        sci.StartStyling(startPos) ; important!
        
        Switch firstChar
        {
            case "-": sci.SetStyling(lineLen,sci.RED_STYLE)
            case "/": sci.SetStyling(lineLen,sci.ORANGE_STYLE)
        }
        i++
    }
}

guiClose(g) {
	DllCall("FreeLibrary", "Ptr", dllHwnd)
	ExitApp
}

showCurrentSelection(sci, lParam, notifyCode) {
	; debug.msg("cb: " cb)
    if (trim(text := GetSelText(sci))) { ; if the selection just contains spaces, this will be false
        ToolTip(text)
        SetTimer(() => ToolTip(), -3000) ; close after 3 seconds
    }
}

GetSelText(sci) { ; helper to get text from buffer
    len := sci.GetSelText()
    text := BufferAlloc(len)
    sci.GetSelText(, text.ptr)
    Return StrGet(Text.ptr, "UTF-8")
}

splitDoc(ctrl, p*) {
    g := ctrl.gui
    
    ; cut the original in half plus some margin
	g["Edit"].GetPos(x,y,w,h), pos := {x:x, y:y, w:w, h:h}
    g["Edit"].move(,,(pos.w - g.marginX) // 2) ; g.control[]
    
    ; make the second control the same width (height was already set) and make it visible
	g["Edit"].GetPos(x,y,w,h), pos := {x:x, y:y, w:w, h:h}
    sci2.ctrl.move(,,pos.w) ; g.control[]
	
    sci2.ctrl.Visible := true
    g["splitDoc"].enabled := false ; g.control[]
    g["unsplitDoc"].enabled := true ; g.control[]
    
    setupSciControl(sci2)
    sci2.SetDocPointer(0, sciDocs[currentDoc])
    
    updateScrollWidth(sci)
}

unSplitDoc(ctrl, p*) {
    g := ctrl.gui				; Set the second control to a new document
    sci2.SetDocPointer(0, 0)	; Set the second control to a new document
    
    sci.ctrl.move(,,800) ; make the main control back to its original width
    
    sci2.ctrl.visible := false
    updateScrollWidth(sci)
    
    g["unsplitDoc"].enabled := false ; g.control[]
    g["splitDoc"].enabled := true ; g.control[]
}

changeDoc(ctrl, p*) {
	next := (ctrl.Name = "NextDoc" ? 1 : 0)
	nextDoc := next ? currentDoc+1 : currentDoc-1
	oldDoc := currentDoc
	
    if (sciDocs.Has(nextDoc)) { ; switch docs only if nextDoc exists
        sci.AddRefDocument(0, sciDocs[currentDoc]) ; add a ref to the current doc before switching
        sci.SetDocPointer(0, sciDocs[nextDoc]) ; change the pointer and reduces ref count
        
        if (ctrl.gui["edit2"].visible) { ; g.control[]
            sci2.SetDocPointer(0, sciDocs[nextDoc])
        }
		
		currentDoc := nextDoc
        
        if (nextDoc = 1) {
            ctrl.gui["prevDoc"].enabled := false ; g.control[]
            ctrl.gui["nextDoc"].enabled := true ; g.control[]
        }
        else if (nextDoc = sciDocs.length) {
            ctrl.gui["prevDoc"].enabled := true ; g.control[]
            ctrl.gui["nextDoc"].enabled := false ; g.control[]
        }
        else {
            ctrl.gui["prevDoc"].enabled := true ; g.control[]
            ctrl.gui["nextDoc"].enabled := true ; g.control[]
        }
    }
}


AddNewDoc(ctrl, p*) {
	oldDoc := currentDoc
	
	sciDocs.push(sci.CreateDocument(1024,0)) ; Save the pointer to the newly created doc
	newDoc := currentDoc+1
	
    sci.AddRefDocument(0, sciDocs[oldDoc]) ; add a ref to the current doc before switching to a new one
    sci.SetDocPointer(0, sciDocs[newDoc]) ; lParam = 0 for new blank document
    
    if (ctrl.gui["edit2"].visible) { ; If showing the second control, set it to point to the same new document
        sci2.SetDocPointer(0, sciDocs[newDoc])
    }
    
    setupSciControl(sci) ; apply generic styling
	currentDoc++
    
    ctrl.gui["prevDoc"].enabled := true
    ctrl.gui["nextDoc"].enabled := false
    ctrl.gui["deleteDoc"].enabled := true
}

deleteDoc(ctrl,info) {
    ; save our pointer of the current doc locally to make things easier
    prevDoc := sciDocs[currentDoc]
    
    ; determine which doc we are going to show after deleting the current one
    ; If we are deleting the last doc, then show the previous one
    ; if we are deleting any other doc, then show the document whose pointer will now occupy the currentDoc position of sciDocs
    showNext := currentDoc = sciDocs.length ? currentDoc - 1 : currentDoc
	
    sci.AddRefDocument(0, sciDocs[currentDoc]) ; Store our own ref to the current document
    
    ; if the split doc is visible, then call the unsplit routine to hide it and release its reference
    if (sci2.ctrl.visible)
        unSplitDoc(ctrl)
    
    sciDocs.RemoveAt(currentDoc) 			; Remove our current doc from tracking
    sci.SetDocPointer(0, sciDocs[showNext]) ; Change the current document to the next one
    
    ; release our ref from the previous document which drops the ref count to 0 and clears the memory
    ; You should never drop the count to 0 if the Scintilla control is the last to own the document
    sci.ReleaseDocument(0, prevDoc)
    
    currentDoc := showNext ; current is now equal to showNext, do this because in this example, currentDoc is global
    newLength := sciDocs.length
    
    if (newLength = currentDoc || newLength = 1) {
        ctrl.gui["nextDoc"].enabled := false
    }
    if (currentDoc = 1) {
        ctrl.gui["prevDoc"].enabled := false
    }
    
    if (newLength = 1) {
        ctrl.gui["deleteDoc"].enabled := false
    }
}

updateScrollWidth(sci) {
    lineNumberWidth := sci.GetMarginWidthN(0)
	
	sci.ctrl.GetPos(x,y,w,h), pos := {x:x, y:y, w:w, h:h}
    sci.SetScrollWidth(pos.w - lineNumberWidth - SysGet(11)) ; Also subtract the width of a vertical scrollbar
}

setupSciControl(sci) {
    sci.SetBufferedDraw(0) ; Scintilla docs recommend turning this off for current systems as they perform window buffering
    sci.SetTechnology(1) ; uses Direct2D and DirectWrite APIs for higher quality

    
    
	sci.SetWrapMode(1) ; wrap on word or style boundaries
	
    ; Indentation
    sci.SetTabWidth(4)
    sci.SetUseTabs(false) ; Indent with spaces
    sci.SetTabIndents(1)
    sci.SetBackspaceUnindents(1) ; Backspace will delete spaces that equal a tab
    sci.SetIndentationGuides(sci.SC_IV_LOOKBOTH)
    
    sci.SetLexer(0) ; SCLEX_CONTAINER - custom styles
    
    sci.StyleSetFont(sci.STYLE_DEFAULT, "Consolas", 1)
    sci.StyleSetSize(sci.STYLE_DEFAULT, 10)
    sci.StyleSetFore(sci.STYLE_DEFAULT, CvtClr(0xF8F8F2))
    sci.StyleSetBack(sci.STYLE_DEFAULT, CvtClr(0x272822))
    sci.StyleClearAll() ; This message sets all styles to have the same attributes as STYLE_DEFAULT.
    
    sci.StyleSetFore(sci.RED_STYLE,CvtClr(0xFF0000)) ; set text red - when i say so...
    sci.StyleSetFore(sci.ORANGE_STYLE,CvtClr(0xFF6600)) ; set text orange...

    ; Active line background color
    sci.SetCaretLineBack(CvtClr(0x3E3D32))
    sci.SetCaretLineVisible(True)
    sci.SetCaretLineVisibleAlways(1)
    sci.SetCaretFore(CvtClr(0xF8F8F0))

    sci.StyleSetFore(sci.STYLE_LINENUMBER, CvtClr(0xF8F8F2)) ; Margin foreground color
    sci.StyleSetBack(sci.STYLE_LINENUMBER, CvtClr(0x272822)) ; Margin background color

    ; Selection
    Sci.SetSelBack(1, CvtClr(0xBEC0BD))
    sci.SetSelAlpha(80)

    ; sci.StyleSetFore(sci.SCE_SQL_COMMENT, CvtClr(0x75715E))
    ; sci.StyleSetFore(sci.SCE_SQL_COMMENTLINE, CvtClr(0x75715E))
    ; sci.StyleSetFore(sci.SCE_SQL_COMMENTDOC, CvtClr(0x75715E))
    ; sci.StyleSetFore(sci.SCE_SQL_COMMENTDOCKEYWORD, CvtClr(0x66D9EF))
    ; sci.StyleSetFore(sci.SCE_SQL_WORD, CvtClr(0xF92672))
    ; sci.StyleSetFore(sci.SCE_SQL_NUMBER, CvtClr(0xAE81FF))
    ; sci.StyleSetFore(sci.SCE_SQL_STRING, CvtClr(0xE6DB74))
    ; sci.StyleSetFore(sci.SCE_SQL_OPERATOR, CvtClr(0xF92672))
    ; sci.StyleSetFore(sci.SCE_SQL_USER1, CvtClr(0x66D9EF))

    ; sci.SetKeywords(0, keywords("keywords"), 1)
    ; sci.SetKeywords(4, keywords("functions"), 1)

    ; line number margin
    PixelWidth := sci.TextWidth(sci.STYLE_LINENUMBER, "9999", 1)
    sci.SetMarginWidthN(0, PixelWidth)
    sci.SetMarginLeft(0, 2) ; Left padding
    
    ; used as a border between line numbers and content
    borderMarginW := 1
    sci.SetMarginTypeN(1, sci.SC_MARGIN_FORE) ; change the second margin to be of type SC_MARGIN_FORE
    sci.SetMarginWidthN(1, borderMarginW) ; set width to 1 pixel
	
	sci.ctrl.GetPos(x,y,w,h), pos := {x:x, y:y, w:w, h:h}
    sci.SetScrollWidth(pos.w - PixelWidth - SysGet(11)) ; Also subtract the width of a vertical scrollbar
}

keywords(key) {
	; Debug.Msg("kw: " key)
    static keywords := {
        keywords: "abort action add after all alter analyze and as asc attach autoincrement before begin between by cascade case cast check collate column commit conflict constraint create cross current current_date current_time current_timestamp database default deferrable deferred delete desc detach distinct do drop each else end escape except exclusive exists explain fail filter following for foreign from full glob group having if ignore immediate in index indexed initially inner insert instead intersect into is isnull join key left like limit match natural no not nothing notnull null of offset on or order outer over partition plan pragma preceding primary query raise range recursive references regexp reindex release rename replace restrict right rollback row rows savepoint select set table temp temporary then to transaction trigger unbounded union unique update using vacuum values view virtual when where window with without",
        functions: "abs avg changes char coalesce count cume_dist date datetime dense_rank first_value glob group_concat hex ifnull instr json json_array json_array_length json_extract json_insert json_object json_patch json_remove json_replace json_set json_type json_valid json_quote json_group_array json_group_object json_each json_tree julianday lag last_insert_rowid last_value lead length like likelihood likely load_extension lower ltrim max min nth_value ntile nullif percent_rank printf quote random randomblob rank replace round row_number rtrim soundex sqlite_compileoption_get sqlite_compileoption_used sqlite_offset sqlite_source_id sqlite_version strftime substr substr sum time total total_changes trim typeof unicode unlikely upper zeroblob"
    }
    
    return keywords.HasProp(key) ? keywords.%key% : ""
}

CvtClr(Color) {
    Return (Color & 0xFF) << 16 | (Color & 0xFF00) | (Color >> 16)
}