var typeAheadInfo = {last:0, 
	accumString:"", 
	delay:500,
	timeout:null, 
	reset:function() {this.last=0; this.accumString=""}
};

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

function activate_link (href) {					
	if (href.indexOf ('javascript:') == 0) {
		var code = href.substr (11).replace (/%20/g, ' ');
		eval (code);
	}
	else {
		document.location.href = href + '&_salt=@{[rand]}';
	}						
}

function blur_all_inputs () {
	var inputs = document.body.getElementsByTagName ('input');
	if (!inputs) return 1;
	for (var i = 0; i < inputs.length; i++) inputs [i].blur ();
	return 0;
}

function focus_on_first_input (td) {
	if (!td) return blur_all_inputs ();
	var inputs = td.getElementsByTagName ('input');
	if (!inputs || !inputs.length) return blur_all_inputs ();
	inputs [0].focus ();
	return 0;
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

		if (window.event.keyCode == 40 && scrollable_table_row < scrollable_rows.length - 1) {

			var effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className = scrollable_table_row_cell_old_style;
			scrollable_table_row ++;
			effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className;
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className = 'txt6';
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].scrollIntoView (false);
			focus_on_first_input (scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell]);
			return false;

		}

		if (window.event.keyCode == 38 && scrollable_table_row > 0) {

			var effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className = scrollable_table_row_cell_old_style;
			scrollable_table_row --;
			effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);
			scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className;
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].className = 'txt6';
			scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell].scrollIntoView ();
			focus_on_first_input (scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell]);
			return false;

		}

		if (window.event.keyCode == 37 && scrollable_table_row_cell > 0) {
			effective_scrollable_cell = Math.min (scrollable_table_row_cell, scrollable_rows [scrollable_table_row].cells.length - 1);													
			if (effective_scrollable_cell > 0) {
				scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
				scrollable_table_row_cell --;
				scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
				scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
				focus_on_first_input (scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell]);
				return false;
			}
		}

		if (window.event.keyCode == 39 && scrollable_table_row_cell < scrollable_rows [scrollable_table_row].cells.length - 1) {

			scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = scrollable_table_row_cell_old_style;
			scrollable_table_row_cell ++;
			scrollable_table_row_cell_old_style = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className;
			scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].className = 'txt6';
			focus_on_first_input (scrollable_rows [scrollable_table_row].cells [effective_scrollable_cell]);
			return false;

		}

		if (window.event.keyCode == 32) {

			var children = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].getElementsByTagName ('input');
			if (children != null && children.length > 0) children [0].checked = !children [0].checked;
		//	return false;

		}

		if (window.event.keyCode == 13) {

			var children = scrollable_rows [scrollable_table_row].cells [scrollable_table_row_cell].getElementsByTagName ('a');
			if (children != null && children.length > 0) activate_link (children [0].href);
			return false;

		}

	}


}
