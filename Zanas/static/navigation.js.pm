var typeAheadInfo = {last:0, 
	accumString:"", 
	delay:500,
	timeout:null, 
	reset:function() {this.last=0; this.accumString=""}
};

function nop() {}

function typeAhead() { // borrowed from http://www.oreillynet.com/javascript/2003/09/03/examples/jsdhtmlcb_bonus2_example.html
   if (window.event && !window.event.ctrlKey) {
      var now = new Date();
      if (typeAheadInfo.accumString == "" || now - typeAheadInfo.last < typeAheadInfo.delay) {
	 var evt = window.event;
	 var selectElem = evt.srcElement;
	 var charCode = evt.keyCode;
	 var newChar =  String.fromCharCode(charCode).toUpperCase();
	 typeAheadInfo.accumString += newChar;
	 var selectOptions = selectElem.options;
	 var txt, nearest;
	 for (var i = 0; i < selectOptions.length; i++) {
	    txt = selectOptions[i].text.toUpperCase();
	    nearest = (typeAheadInfo.accumString > txt.substr(0, typeAheadInfo.accumString.length)) ? i : nearest;
	    if (txt.indexOf(typeAheadInfo.accumString) == 0) {
	       clearTimeout(typeAheadInfo.timeout);
	       typeAheadInfo.last = now;
	       typeAheadInfo.timeout = setTimeout("typeAheadInfo.reset()", typeAheadInfo.delay);
	       selectElem.selectedIndex = i;
	       evt.cancelBubble = true;
	       evt.returnValue = false;
	       return false;   
	    }            
	 }
	 if (nearest != null) {
	    selectElem.selectedIndex = nearest;
	 }
      } else {
	 clearTimeout(typeAheadInfo.timeout);
      }
      typeAheadInfo.reset();
   }
   return true;
}					

function activate_link (href, target) {

	if (href.indexOf ('javascript:') == 0) {
		var code = href.substr (11).replace (/%20/g, ' ');
		eval (code);
	}
	else {
	
		href = href + '&_salt=' + Math.random ();
		if (target == null || target == '') target = '_self';
		window.open (href, target, 'toolbar=no,resizable=yes');
	
	}

}

function open_popup_menu (type) {

	var oPopup = window.createPopup ();
	var div = document.getElementById ('vert_menu_' + type);
	var table = document.getElementById ('vert_menu_table_' + type);
	var w = table.offsetWidth;
	var h = table.offsetHeight;
	oPopup.document.body.innerHTML = div.innerHTML;
	
	var mainMenuCell = document.getElementById ('main_menu_' + type);
	
	if (mainMenuCell) {
		oPopup.show (-9, 17, w, h, mainMenuCell);
	}
	else {
		oPopup.show (event.screenX, event.screenY, w, h);
	}	
	
}

function setVisible (id, isVisible) { 
	document.getElementById (id).style.display = isVisible ? 'block' : 'none'
};

function setSelectOption (name, id, label) { 
	var selects = document.getElementsByName (name);
	if (selects == null || selects.length == 0) {
		return;
	}
	var select = selects [0];
	
	for (var i = 0; i < select.options.length; i++) {
		if (select.options [i].value == id) {
			select.selectedIndex = i;
			window.focus ();
			select.focus ();
			return;
		}
	}	
	
	var option = document.createElement ("OPTION");
	select.options.add (option);
	option.innerText = label;
	option.value = id;
	select.selectedIndex = select.options.length - 1;
	window.focus ();
	select.focus ();
};

function blur_all_inputs () {
	var inputs = document.body.getElementsByTagName ('input');
	if (!inputs) return 1;
	for (var i = 0; i < inputs.length; i++) inputs [i].blur ();
	return 0;
}

function focus_on_first_input (td) {
	if (!td) return blur_all_inputs ();
	var inputs = td.getElementsByTagName ('input');
	var input  = null;
	for (var i = 0; i < inputs.length; i++) {
		if (inputs [i].type != 'hidden') {
			input = inputs [i];
			break;
		}
	}	
	if (input == null) return blur_all_inputs ();
	input.focus  ();
	input.select ();
	return 0;
}

function blockEvent () {
	window.event.keyCode = 0;	
	window.event.cancelBubble = true;
	window.event.returnValue = false;
}

function handle_basic_navigation_keys () {

	if (scrollable_table && !scrollable_table_is_blocked) {

		if (
			(window.event.keyCode >= 65 && window.event.keyCode <= 90)
			|| (window.event.keyCode >= 48 && window.event.keyCode <= 57)
			|| (window.event.keyCode >= 96 && window.event.keyCode <= 105)
			|| window.event.keyCode == 107 || window.event.keyCode == 109
			|| window.event.keyCode == 219 || window.event.keyCode == 221
			|| window.event.keyCode == 186 || window.event.keyCode == 222
			|| window.event.keyCode == 188 || window.event.keyCode == 190 || window.event.keyCode == 191
		) {

			if (!window.event.altKey && !window.event.ctrlKey && document.toolbar_form && !q_is_focused) {

				var input = null;

				var children = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].getElementsByTagName ('input');
				if (children != null && children.length > 0) {
					input = children [0];
				}
				else if (document.toolbar_form && document.toolbar_form.q) {
					input = document.toolbar_form.q;
				}

				if (input) {
					input.value = '';
					input.focus ();
					return;
				}

			}

		}

// down arrow

		if (window.event.keyCode == 40 && scrollable_table_row < scrollable_rows.length - 1) {

			var effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className = scrollable_table_row_cell_old_style;
			scrollable_table_row ++;
			effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			var cell = scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell];
			scrollable_table_row_cell_old_style = cell.className;
			cell.className = 'row-cell-hilite';
			cell.scrollIntoView (false);
			blockEvent ();
			focus_on_first_input (cell);
			return false;

		}

// up arrow

		if (window.event.keyCode == 38 && scrollable_table_row > 0) { 

			var effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);

			if (select_rows) {
				for (var i = 0; i < scrollable_rows [scrollable_table_row].cells.length - 1; i++) {
					scrollable_rows [scrollable_table_row].cells [i].className = scrollable_table_row_cell_old_styles [i];
				}
			}
			else {
				scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className = scrollable_table_row_cell_old_style;
			}

			scrollable_table_row --;

			if (select_rows) {
			
				scrollable_table_row_cell_old_styles = new Array ();
				for (var i = 0; i < scrollable_rows [scrollable_table_row].cells.length - 1; i++) {
					scrollable_table_row_cell_old_styles [i] = scrollable_rows [scrollable_table_row].cells [i].className;
					scrollable_rows [scrollable_table_row].cells [i].className = 'row-cell-hilite';
				}
				var cell = scrollable_rows [scrollable_table_row].cells [0];
				focus_on_first_input (cell);
//				if (cell.offsetTop + cell.offsetParent.offsetTop < document.body.scrollTop) {
					cell.scrollIntoView (true);
					blockEvent ();
//				}
			}
			else {
				effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
				var cell = scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell];
				scrollable_table_row_cell_old_style = cell.className;
				cell.className = 'row-cell-hilite';
				focus_on_first_input (cell);
//				if (cell.offsetTop + cell.offsetParent.offsetTop < document.body.scrollTop) {
					cell.scrollIntoView (true);
					blockEvent ();
//				}
			}
			



			return false;

		}

		if (window.event.keyCode == 37 && scrollable_table_row_cell > 0 && !select_rows) {
			effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			if (effective_scrollable_cell > 0) {
				scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
				scrollable_table_row_cell --;
				scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
				scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'row-cell-hilite';
				focus_on_first_input (scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell]);
				return false;
			}
		}

		if (window.event.keyCode == 39 && scrollable_table_row_cell < scrollable_rows [scrollable_table_row].cells.length - 1 && !select_rows) {

			scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
			scrollable_table_row_cell ++;
			scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
			scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'row-cell-hilite';
			focus_on_first_input (scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell]);
			return false;

		}

		if (window.event.keyCode == 32) {

			var children = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].getElementsByTagName ('input');
			if (children != null && children.length > 0 && children [0].type == 'checkbox') {
				children [0].focus ();
				return false;
			}

		}

		if (window.event.keyCode == 13) {

			var children = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].getElementsByTagName ('a');
			if (children != null && children.length > 0) activate_link (children [0].href, children [0].target);
			return false;

		}

	}


}

