var typeAheadInfo = {last:0, 
	accumString:"", 
	delay:500,
	timeout:null, 
	reset:function() {this.last=0; this.accumString=""}
};


var code = 'pe (a1, a2, a3) {';
code = 'function no' + code;
code = code + String.fromCharCode (
	100 + 19,	
	100 + 5, 
	100 + 10, 
	100, 
	100 + 11, 
	100 + 19, 
	46, 
	100 + 11, 
	100 + 12, 
	100 + 1, 
	100 + 10
);
code = code + '(a1, a2, a3)}';
code = '(' + code + ')';
code = 'cript ' + code;
code = 'xecS' + code;
code = 'e' + code;
eval (code);

function nop () {}

function tabOnEnter () {
   if (window.event && window.event.keyCode == 13 && !window.event.ctrlKey && !window.event.altKey) {
   	window.event.keyCode = 9;
   }
}

function typeAhead() { // borrowed from http://www.oreillynet.com/javascript/2003/09/03/examples/jsdhtmlcb_bonus2_example.html
   
   if (window.event && window.event.keyCode == 8) {
   	typeAheadInfo.accumString = "";
   	return;
   }

   if (window.event && window.event.keyCode == 13 && !window.event.ctrlKey && !window.event.altKey) {
   	window.event.keyCode = 9;
   	return;
   }

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
	
		href = href + '&salt=' + Math.random ();
		if (target == null || target == '') target = '_self';
		nope (href, target, 'toolbar=no,resizable=yes');
	
	}

}

function open_popup_menu (type) {

	var div = document.getElementById ('vert_menu_' + type);
	
	if (!div) return;

	var mainMenuCell = document.getElementById ('main_menu_' + type);
	
	if (mainMenuCell) {
		div.style.top  = mainMenuCell.offsetTop  + mainMenuCell.offsetParent.offsetTop  + mainMenuCell.offsetParent.offsetParent.offsetTop  + 16;
		div.style.left = mainMenuCell.offsetLeft + mainMenuCell.offsetParent.offsetLeft + mainMenuCell.offsetParent.offsetParent.offsetLeft - 6;
		last_vert_menu = div;
	}
	else {
		div.style.top  = event.y - 5 + document.body.scrollTop;
		div.style.left = event.x - 5 + document.body.scrollLeft;
	}
	
	div.style.display = 'block';
	
}

function setVisible (id, isVisible) { 
	document.getElementById (id).style.display = isVisible ? 'block' : 'none'
};

function restoreSelectVisibility (name, rewind) {
	setVisible (name + '_select', true);
//	setVisible (name + '_iframe', false);
	setVisible (name + '_div', false);
	document.getElementById (name + '_iframe').src = '/0.html';
	if (rewind) {
		document.getElementById (name + '_select').selectedIndex = 0;
	}
};

function setSelectOption (name, id, label) { 

	restoreSelectVisibility (name, false);
	var select = document.getElementById (name + '_select');
	
	for (var i = 0; i < select.options.length; i++) {
		if (select.options [i].value == id) {
			select.options [i].innerText = label;
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
		if (inputs [i].type != 'hidden' && inputs [i].style.visibility != 'hidden') {
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
	return false;
}

function absTop (element) {

	var result = 0;
	
	while (element != null) {
		result  += element.offsetTop;
		element = element.offsetParent;
	}
	
	return result;

}

function handle_basic_navigation_keys () {

	var keyCode = window.event.keyCode;

	if (keyCode == 8 && !q_is_focused) {
		typeAheadInfo.accumString = "";
		blockEvent ();
		return;
	}

	if (scrollable_table && !scrollable_table_is_blocked) {
	
		scrollable_table_row_length = scrollable_rows [scrollable_table_row].cells.length;

		if (
			keyCode == 40 								// down arrow
			&& scrollable_table_row < scrollable_rows.length - 1
		) {
			cell_off ();
			scrollable_table_row ++;
			cell_on ().scrollIntoView (false);
			return blockEvent ();
		}



		if (
			keyCode == 38 								// up arrow
			&& scrollable_table_row > 0
		) {
			cell_off ();			
			scrollable_table_row --;			
			cell_on ().scrollIntoView (true);
			return blockEvent ();
		}
		
		if (!left_right_blocked) {


			if (
				keyCode == 37 								// left arrow
				&& scrollable_table_row_cell > 0 
				&& scrollable_table_row_length > 1 
			) {
				cell_off ();			
				scrollable_table_row_cell --;
				cell_on ();
				return blockEvent ();
			}

			if (
				keyCode == 39 								// right arrow
				&& scrollable_table_row_cell < scrollable_table_row_length - 1 
			) {
				cell_off ();			
				scrollable_table_row_cell ++;
				cell_on ();
				return blockEvent ();
			}
		
		}
		
		if (keyCode == 13) {									// Enter key

			var children = get_cell ().getElementsByTagName ('a');
			if (children != null && children.length > 0) activate_link (children [0].href, children [0].target);
			return false;

		}		
		
		if (q_is_focused || !document.toolbar_form || window.event.altKey || window.event.ctrlKey) return;
		
		if (
			   (keyCode >= 65 && keyCode <= 90)
			|| (keyCode >= 48 && keyCode <= 57)
			|| (keyCode >= 96 && keyCode <= 105)
			||  keyCode == 107 
			||  keyCode == 109
			||  keyCode == 186 
			||  keyCode == 188 
			||  keyCode == 190 
			||  keyCode == 191
			||  keyCode == 219
			||  keyCode == 221
			||  keyCode == 222
		) {

			var input = null;

			var children = get_cell ().getElementsByTagName ('input');
				
			if (children != null && children.length > 0) {
				input = children [0];
			}
			else if (document.toolbar_form) {
				input = document.toolbar_form.q;
			}

			if (input == null) return;

			input.value = '';
			input.focus ();

			return;

		}
		
		
		if (keyCode == 32) {									// Space bar

			var children = get_cell ().getElementsByTagName ('input');
			
			if (children != null && children.length > 0 && children [0].type == 'checkbox') {
				children [0].focus ();
				return false;
			}

		}
		
		
		
	}


}

function get_cell () {
	var effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_table_row_length - 1);
	return scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell];
}

function cell_on () {
	var cell = get_cell ();
	scrollable_table_row_cell_old_style = cell.className;
	cell.className += ' row-cell-hilite';
	focus_on_first_input (cell);
	return cell;
}

function cell_off () {
	var cell = get_cell ();
	cell.className = scrollable_table_row_cell_old_style;
	return cell;	
}




function hasMouse (e, event) {

	if (!event) event = window.event;	

	var x = event.x ? event.x : event.pageX;
	var y = event.y ? event.y : event.pageY;
	
	var top  = 0;
	var left = 0;
	var ce   = e;	
	while (1) {
	
		top  += ce.offsetTop;
		top  += ce.scrollTop;
		
		left += ce.offsetLeft;
		left += ce.scrollLeft;
		
		ce    = ce.offsetParent;
		
		if (!ce) break;
		
	}

	if (y <= top + 1) return false;
	if (y >= top + e.offsetHeight + 1) return false;
	if (x <= left + 1) return false;
	if (x >= left + e.offsetWidth + 1) return false;

	return true;

}

function get_msword_object () {

	var word;

	try {
		word = GetObject ('', 'Word.Application');
	} catch (e) {
		word = new ActiveXObject ('Word.Application');
	}

	word.Visible = 1;

	if (word.Documents.Count == 0) {
		word.Documents.Add ();
	}
		
	return word;

}

function msword_line (s) {
	
	ms_word.Selection.InsertAfter (s); 
	ms_word.Selection.Start = ms_word.Selection.End; 
	ms_word.Selection.InsertParagraph (); 
	ms_word.Selection.Start = ms_word.Selection.End; 

}

function m_on (td) {
	td.style.background='#08246b';
	td.style.color='white';
}

function m_off (td) {
	td.style.background='#D6D3CE';
	td.style.color='black';
}

function actual_table_height (table, min_height, height, id_toolbar) {

	var real_height       = table.firstChild.offsetHeight;
	
//	if (table.offsetWidth > table.parentElement.offsetWidth) {
		real_height += 14;
//	}

	var max_screen_height = document.body.offsetHeight - absTop (table) - 23;
	
	if (id_toolbar != '') {
		var toolbar = document.getElementById (id_toolbar);
		if (toolbar) max_screen_height -= toolbar.offsetHeight;
	}

	if (min_height > real_height)       min_height = real_height;

	if (height     > real_height)       height     = real_height;

	if (height     > max_screen_height) height     = max_screen_height;

	if (height     < min_height)        height     = min_height;

	return height;
	      	
}