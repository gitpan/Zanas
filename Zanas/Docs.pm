package Zanas::Docs;

package main;

@langs = qw(en ru);

################################################################################

@options = (

	{
		name     => 'code',
		label_en => "Keyboard scan code. Can be set as /F(\d+)/ for function keys.",
		label_ru => "Клавиатурный scan code. Для функциональных клавиш может быть задан как /F(\d+)/.",
	},

	{
		name     => 'data',
		label_en => "ID attibute of an A tag to activate with the hotkey.",
		label_ru => "Атрибут ID тега A, который требуется активизировать при нажатии на горячую клавишу.",
	},

	{
		name     => 'ctrl',
		label_en => "If true, Ctrl key must be pressed.",
		label_ru => "Если истина, требуется нажатие на Ctrl.",
	},

	{
		name     => 'alt',
		label_en => "If true, Alt key must be pressed.",
		label_ru => "Если истина, требуется нажатие на Alt.",
	},

	{
		name     => 'no_force_download',
		label_en => "Unless true, the 'File download' ialog is forced on the client.",
		label_ru => "Если не true, то на клиенте должен появиться диалог открытия файла.",
	},

	{
		name     => 'file_name',
		label_en => "File name as shown to the client.",
		label_ru => "Имя файла для клиента.",
	},

	{
		name     => 'file_path_columns',
		label_en => "Listref of names of column that contain attached file paths.",
		label_ru => "Список имён полей, содержащих пути прикреплённых файлов.",
	},

	{
		name     => 'table',
		label_en => 'Table name.',
		label_ru => 'Имя таблицы.',
	},

	{
		name     => 'dir',
		label_en => 'Directory name to store the file, relative to DocumentRoot.',
		label_ru => 'Имя директории для записи файла, относительно DocumentRoot.',
	},

	{
		name     => 'path',
		label_en => 'File path, relative to DocumentRoot.',
		label_ru => 'Путь к файлу, относительно DocumentRoot.',
	},

	{
		name     => 'size_column',
		label_en => 'Name of the column that contain file size.',
		label_ru => 'Имя поля, содержащего обём прикреплённого файла.',
	},

	{
		name     => 'path_column',
		label_en => 'Name of the column that contain file path.',
		label_ru => 'Имя поля, содержащего путь прикреплённого файла.',
	},

	{
		name     => 'type_column',
		label_en => 'Name of the column that contain file MIME type.',
		label_ru => 'Имя поля, содержащего MIME-тип прикреплённого файла.',
	},

	{
		name     => 'file_name_column',
		label_en => 'Name of the column that contain file name.',
		label_ru => 'Имя поля, содержащего имя прикреплённого файла.',
	},

	{
		name     => 'label',
		label_en => "Visible text displayed in the element's area.",
		label_ru => "Видимый текст, отображаемый элементом.",
	},

	{
		name     => 'off',
		label_en => "If true, the element is not drawn at all",
		label_ru => "Если true, то HTML-код елемента не генерируется",
	},

	{
		name     => '..',
		label_en => "If true and the path is present on the page, the first table row is the reference to the previous level of the path (like '..' in file system).",
		label_ru => "Если true и на странице есть path, то первая строка таблицы ссылается на предпоследний элемент path (как '..' в файловой системе)",
	},

	{
		name     => 'height',
		label_en => "Height, in pixels",
		label_ru => "Высота, в пикселях",
	},

	{
		name     => 'class',
		label_en => "CSS class name",
		label_ru => "Имя CSS-класса",
	},

	{
		name     => 'read_only',
		label_en => "If true, text inputs are replaced by static text + hidden inputs",
		label_ru => "Если true, то текстовые поля ввода превращаются в статический текст + скрытые (hidden) поля",
	},
	
	{
		name     => 'max_len',
		label_en => "Maximum length for the displayed text. If oversized, the text is truncated and '...' is appended",
		label_ru => "Максимальная длина выводимого текста. При превышении текст обрезается, и к нему приписывается '...'",
	},
	
	{
		name     => 'size',
		label_en => "Size of the input field",
		label_ru => "Длина поля текстового ввода",
	},

	{
		name     => 'attributes',
		label_en => "additional HTML attributes for the corresponding TD tag",
		label_ru => "дополнительные HTML-атрибуты, дописываемые в тег TD",
	},
	
	{
		name     => 'a_class',
		label_en => "CSS class name for A tag",
		label_ru => "Имя CSS-класса для тега A",
	},

	{
		name     => 'name',
		label_en => "Input or form name",
		label_ru => "Имя поля ввода или всей формы",
	},

	{
		name     => 'type',
		label_en => "The value for the hidden input named 'type'",
		label_ru => "Значение, передаваемое невидимым полем ввода 'type'",
	},

	{
		name     => 'id',
		label_en => "The value for the hidden input named 'id'",
		label_ru => "Значение, передаваемое невидимым полем ввода 'id'",
	},

	{
		name     => 'action',
		label_en => "The value for the hidden input named 'action'",
		label_ru => "Значение, передаваемое невидимым полем ввода 'action'",
	},

	{
		name     => 'toolbar',
		label_en => "The toolbar on bottom of the table (inside its FORM tag)",
		label_ru => "Панель с кнопками внизу таблицы (внутри соответствующего тега FORM)",
	},

	{
		name     => 'js_ok_escape',
		label_en => "If true, the Ctrl+Enter and Esc keys will submit/escape the current form",
		label_ru => "Если true, то Ctrl+Enter и Esc обрабатываются для этой формы",
	},

	{
		name     => 'checked',
		label_en => "If true, the checkbox is on",
		label_ru => "Если true, checkbox отмечен",
	},

	{
		name     => 'value',
		label_en => "The input's value",
		label_ru => "Значение элемента управления",
	},
	
	{
		name     => 'hidden_value',
		label_en => "The hidden input's value",
		label_ru => "Значение элемента управления типа hidden",
	},

	{
		name     => 'id_image',
		label_en => "The hidden input's value",
		label_ru => "Значение элемента управления типа hidden",
	},

	{
		name     => 'hidden_name',
		label_en => "The hidden input's name",
		label_ru => "Имя элемента управления типа hidden",
	},

	{
		name     => 'picture',
		label_en => "The picture for numeric data (see Number::Format)",
		label_ru => "Формат числовых значений (см. Number::Format)",
	},
	
	{
		name     => 'href',
		label_en => "URL pointed by the element (HREF attribute of the A tag). Magic parameters 'sid' and 'salt' are appended automatically. See <a href='check_href.html'>check_href</a>, <a href='create_url.html'>create_url</a>",
		label_ru => "URL, на который ссылается данный элемент (атрибут HREF тега A). Магические параметры 'sid' и 'salt' приписываются автоматически. См. также <a href='check_href.html'>check_href</a>, <a href='create_url.html'>create_url</a>",
	},
	
	{
		name     => 'target',
		label_en => "The target window/frame (TARGET attribute of the A tag)",
		label_ru => "Целевое окно/фрейм ссылки (атрибут TARGET тега A)",
	},

	{
		name     => 'icon',
		label_en => "Reserved",
		label_ru => "Зарезервировано",
	},

	{
		name     => 'confirm',
		label_en => "The confirmation text",
		label_ru => "Текст запроса на подтверждение действия",
	},

	{
		name     => 'multiline',
		label_en => "If true, multiline mode is on",
		label_ru => "Если true, то отрисовка многострочная",
	},
	
	{
		name     => 'id_param',
		label_en => "Name of the param which value must be set to the current object ID",
		label_ru => "Имя параметра, в качестве значения которого должен быть передан ID текущего объекта",
	},
	
	{
		name     => 'keep_params',
		label_en => "REQUEST params to be inherited.",
		label_ru => "Список параметров запроса, которые требуется унаследовать.",
	},

	{
		name     => 'cnt',
		label_en => "Number of table rows on the current page (with START/LIMIT clause).",
		label_ru => "Число строк таблицы на текущей странице (с учётом START/LIMIT).",
	},

	{
		name     => 'total',
		label_en => "Total number of table rows (without START/LIMIT clause).",
		label_ru => "Число строк таблицы на текущей странице (без учёта START/LIMIT).",
	},

	{
		name     => 'portion',
		label_en => "Maximum number of table rows on one page (LIMIT value)",
		label_ru => "Максимальное число строк таблицы на одной странице (LIMIT)",
	},

	{
		name     => 'bottom_toolbar',
		label_en => "Toolbar on bottom of the form",
		label_ru => "Панель с копками внизу формы ввода",
	},

	{
		name     => 'format',
		label_en => "Date/time format, for example '%d.%m.%Y %k:%M'",
		label_ru => "Формат даты/времени, например, '%d.%m.%Y %k:%M",
	},

	{
		name     => 'no_time',
		label_en => "If true, no time is selected, only date",
		label_ru => "Если true, редактируется только дата, но не время",
	},
	
	{
		name     => 'onClose',
		label_en => "JavaScript code handling for the 'onClose' event",
		label_ru => "JavaScript-код обработчика события 'onClose'",
	},
	
	{
		name     => 'onChange',
		label_en => "JavaScript code handling for the 'onChange' event",
		label_ru => "JavaScript-код обработчика события 'onChange'",
	},
	
	{
		name     => 'onclick',
		label_en => "JavaScript code handling for the 'onclick' event",
		label_ru => "JavaScript-код обработчика события 'onclick'",
	},

	{
		name     => 'items',
		label_en => "Listref containing subelement definitions",
		label_ru => "Ссылка на список, содержащий описания подэлементов",
	},

	{
		name     => 'src',
		label_en => "Value of SRC attribute of IMG tag (image URL)",
		label_ru => "Значение атрибута SRC тега IMG (адрес изображения)",
	},

	{
		name     => 'new_image_url',
		label_en => "Path to image selection dialog box",
		label_ru => "Адрес страницы выбора изображения",
	},

	{
		name     => 'rows',
		label_en => "Value of ROWS attribute of TEXTAREA tag (textarea height)",
		label_ru => "Значение атрибута ROWS тега TEXTAREA (высота редактора)",
	},

	{
		name     => 'width',
		label_en => "Value of WIDTH attribute.",
		label_ru => "Значение атрибута WIDTH (ширина)",
	},

	{
		name     => 'height',
		label_en => "Value of HEIGHT attribute",
		label_ru => "Значение атрибута HEIGHT (высота)",
	},

	{
		name     => 'cols',
		label_en => "Value of COLS attribute of TEXTAREA tag (textarea width)",
		label_ru => "Значение атрибута COLS тега TEXTAREA (ширина редактора)",
	},

	{
		name     => 'values',
		label_en => "Data dictionnary for a field: arrayref of hashrefs with fields 'id' (possible field value) and 'label' (displayed). In 'checkboxes' field, hashrefs can contain 'items' elements referring to similar arrays, in this case, the tree is displayed.",
		label_ru => "Словарь данных для поля редактирования: список хэшей с ключами 'id' (возможное значение поля) и 'label' (видимая метка). Для поля типа 'checkboxes' хэши могут содержать элементы 'items' со ссылками на аналогичные массивы: в этом случае отрисовывается дерево.",
	},

	{
		name     => 'empty',
		label_en => "Label corresponding to a non-positive value (first in list), like '[no value]', '<Choose sometyhing!>' etc.",
		label_ru => "Надпись, соответствующая неположительному значению поля, появляется первой в списке. Как правило, это '[не определено]', '<Выберите!>' и т. п.",
	},

	{
		name     => 'esc',
		label_en => "URL referenced by the Escape button (also opened when pressing hardware Esc)",
		label_ru => "Ссылка с кнопки 'выход', открываемая также при нажатии на клавишу Esc",
	},

	{
		name     => 'back',
		label_en => "URL referenced by the Back button (also opened when pressing hardware Esc)",
		label_ru => "Ссылка с кнопки 'назад', открываемая также при нажатии на клавишу Esc",
	},

	{
		name     => 'additional_buttons',
		label_en => "Additional buttons definitions",
		label_ru => "Описания дополнительных кнопок",
	},

	{
		name     => 'label_ok',
		label_en => "Label for the OK button",
		label_ru => "Надпись на кнопке OK",
	},

	{
		name     => 'label_cancel',
		label_en => "Label for the Cancel button",
		label_ru => "Надпись на кнопке Cancel",
	},

	{
		name     => 'no_ok',
		label_en => "If true and 'bottom_toolbar' is undefined then draw_esc_toolbar is invoked instead of draw_ok_esc_toolbar.",
		label_ru => "Если true и 'bottom_toolbar' неопределена, то вместо draw_ok_esc_toolbar вызывается draw_esc_toolbar.",
	},

	{
		name     => 'root',
		label_en => "Supplementary path record inserted before the first one",
		label_ru => "Дополнительная запись path, предшествующая всем осальным.",
	},

);

################################################################################

@subs = (

					#######################################

	{
		name     => 'create_url',
#		options  => [qw()],
		syn      => <<EO,	
	create_url (
		type => 'some_other_type',
	);
	
	# /?type=my_type&id=1&sid=123456&_foo=bar --> /?type=some_other_type&id=1&sid=123456
	
EO
		label_en => 'Creates the URL inheriting all parameter values but explicitely set and starting with one underscore. Automatically applied to any HASHREF valued "href" option.',
		label_ru => 'Генерирует URL, наследующий значения всех параметров, кроме упомянутых в списке аргументов и тех, чьи имена начинаются с символа \'_\'. Неявно применяется ко всем значениям опции "href", которые заданы как ссылка на хэш',
		see_also => [qw(check_href)],
	},

					#######################################

	{
		name     => 'check_title',
#		options  => [qw()],
		syn      => <<EO,	
	check_title ({
		...
		label => 'project "Y"',
		...
	});

	# --> {	
	# ...
	# label => 'project "Y"',
	# title => 'title="project &amp;quot;Y&amp;quot;"'
	# ...
	# }	
	
EO
		label_en => 'Adds a properly quoted TITLE tag to options hashref. Defaults to label option.',
		label_ru => 'Добавляет в опции HTML-код для атрибута TITLE. Значение по умолчанию берётся из опции label.',
		see_also => [qw(create_url)],
	},
				
					#######################################

	{
		name     => 'check_href',
#		options  => [qw()],
		syn      => <<EO,	
	check_href ({
		...
		href => "/?type=users",
		...
	});
	
	# /?type=users --> /?type=users&sid=3543522543214387&_salt=0.635735452454
	
EO
		label_en => 'Ensures the sid parameter inheritance (session support through URL rewriting) and _salt parameter randomness (prevents from client side cacheing). Automatically applied to any option set with scalar "href" option.',
		label_ru => 'Обеспечивает наследование параметра sid (сессии через URL rewriting) и случайность параметра _salt (защипа от кэширования на клиенте). Неявно применяется ко всем наборам опциий со скалярной "href"',
		see_also => [qw(create_url)],
	},


					#######################################

	{
		name     => 'hotkeys',
		options  => [qw(code data ctrl alt off)],
		syn      => <<EO,	
	hotkeys (
		{
			code => F4,
			data => 'edit_button',
			off  => \$_REQUEST {edit},
		},
		{
			code => F10,
			data => 'ok',
			off  => \$_REQUEST {__read_only},
		},
	);
EO
		label_en => 'Setting hotkeys for anchors with known IDs.',
		label_ru => 'Установка клавиатурных ускорителей для гиперссылок с известными атрибутами ID.',
#		see_also => [qw()],
	},

					#######################################

	{
		name     => 'delete_fakes',
		syn      => <<EO,	
	delete_fakes ('users');
EO
		label_en => 'Garbage collection: delete fake records which belong to non-active sessions. Automatically invoked before any "do_create_$type" callback sub.',
		label_ru => 'Сборка мусора: удаление всех fake-записей, принадлежащих неактивным сессиям. Автоматически вызывается перед каждой callback-процедурой "do_create_$type".',
#		see_also => [qw()],
	},

					#######################################

	{
		name     => 'download_file',
		options  => [qw(file_name path no_force_download)],
		syn      => <<EO,	
	download_file ({
		file_name         => 'report.doc',
		path              => '/i/upload/misc/543543545735-5455',
		no_force_download => 1,
	});
EO
		label_en => 'Sends the file response to the client.',
		label_ru => 'Инициирует загрузку файла на клиент.',
		see_also => [qw(sql_download_file upload_file)],
	},

					#######################################

	{
		name     => 'sql_do_update',
		syn      => <<EO,	
	sql_do_update ('users', ['name', 'login']);
EO
		label_en => 'Updates the record with id = $_REQUEST {id} in the table which name is the 1st argument. Updated fields are listed in the 2nd argument. The value for each field $f is $_REQUEST {"_$f"}. Moreover, the "fake" field is set to 0 unless the 3rd argument is true.',
		label_ru => 'Обновляет запись c id = $_REQUEST {id} в таблице, имя которой есть 1-й аргумент. Список обновляемых полей -- 2-й аргумент. Значение каждого поля $f определяется как $_REQUEST {"_$f"}. В поле "fake" записывается 0, если только не является истиной 3-й аргумент.',
		see_also => [qw(sql_do_insert sql_do_delete)]
	},

					#######################################

	{
		name     => 'sql_do_insert',
		syn      => <<EO,	
	sql_do_insert ('users', {
		name1	=> 'No',
		name2	=> 'Name',
	});
EO
		label_en => 'Inserts a new record in the table and returns its ID. Unless the "fake" value is set, it defaults to $_REQUEST {sid}.',
		label_ru => 'Вставляет новую запись в таблицу и возвращает её номер. Если значение "fake" не задано, оно принимается равным $_REQUEST {sid}.',
		see_also => [qw(sql_do_update sql_do_delete)]
	},

					#######################################

	{
		name     => 'upload_file',
		options	 => [qw(name dir)],
		syn      => <<EO,	
	my \$file = sql_upload_file ({
		name             => 'photo',
		dir		 => 'i/upload/user_photos'
	});
	
#	{
#		file_name => 'C:\sample.jpg',
#		size      => 86219,
#		type      => 'image/jpeg',
#		path      => 'i/upload/user_photos/57387635438-3543',
#		real_path => '/var/virtualhosts/myapp/docroot/i/upload/user_photos/57387635438-3543'
#	};
	
EO
		label_en => 'Uploads the file.',
		label_ru => 'Загружает файл на сервер.',
		see_also => [qw(sql_upload_file download_file)],
	},


					#######################################

	{
		name     => 'sql_upload_file',
		options	 => [qw(name dir table path_column type_column file_name_column size_column)],
		syn      => <<EO,	
	sql_upload_file ('users', {
		name             => 'photo',
		table            => 'users',
		dir		 => 'i/upload/user_photos'
		path_column      => 'path_photo',
		type_column      => 'type_photo',
		file_name_column => 'flnm_photo',
		size_column      => 'size_photo',
	});
EO
		label_en => 'Uploads the file and stores its info in the table.',
		label_ru => 'Загружает файл еа сервер и записывает его данные в таблицу.',
		see_also => [qw(upload_file sql_download_file)],
	},

					#######################################

	{
		name     => 'sql_download_file',
		options	 => [qw(path_column type_column file_name_column)],
		syn      => <<EO,	
	sql_download_file ('users', {
		path_column      => 'path_photo',
		type_column      => 'type_photo',
		file_name_column => 'flnm_photo',
	});
EO
		label_en => 'Sends the file download response. The file info is fetched from the table record with with id = $_REQUEST {id}.',
		label_ru => 'Инициирует загрузку файла на клиент. Информация о файле берётся из записи таблицы с id = $_REQUEST {id}.',
		see_also => [qw(sql_upload_file)],
	},


					#######################################

	{
		name     => 'sql_do_delete',
		syn      => <<EO,	
	sql_do_delete ('users', {
		file_path_columns => ['path_photo'],
	});
EO
		label_en => 'Deletes the record with id = $_REQUEST {id} in the table which name is the 1st argument. With all attached files, if any.',
		label_ru => 'Удаляет из таблицы запись с id = $_REQUEST {id}. Если заданы file_path_columns, то стирает соответствующие файлы.',
		see_also => [qw(sql_do_update sql_do_insert)]
	},

					#######################################

	{
		name     => 'sql_last_insert_id',
		syn      => <<EO,	
	my $id = sql_last_insert_id;
EO
		label_en => 'Fetches the last INSERT ID. Usually you should not call this sub directly. Use the sql_do_insert return value instead.',
		label_ru => 'Возвращает последний сгенерированный ID. Как правило, вместо этой функции желатенльно использовать значение, вычисляемое sql_do_insert.',
		see_also => [qw(sql_do_insert)]
	},

					#######################################

	{
		name     => 'add_vocabularies',
		syn      => <<EO,	
	\$item -> add_vocabularies ('roles', 'departments', 'sexes');
EO
		label_en => 'Add multiple data vocabularies simultanuousely.',
		label_ru => 'Добавляет к объекту сразу несколько словарей данных.',
		see_also => [qw(sql_select_vocabulary)]
	},

					#######################################

	{
		name     => 'sql_do',
		syn      => <<EO,	
	sql_do ('INSERT INTO my_table (id, name) VALUES (?, ?)', \$id, \$name);
EO
		label_en => 'Executes the DML statement with the given arguments.',
		label_ru => 'Исполняет оператор DML с заданными аргументами.',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_all_cnt',
		syn      => <<EOP,	
	my (\$rows, \$cnt)= sql_select_all_cnt (&lt;&lt;EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			...
		ORDER BY 
			...
		LIMIT
			\$start, 15
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs) and the number of rows in the corresponding selection without the LIMIT clause.',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает выборку (список хэшей), а также объём выборки без учёта ограничителя LIMIT.',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_all',
		syn      => <<EOP,	
	my \$rows = sql_select_all (&lt;&lt;EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			...
		ORDER BY 
			...
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the resultset (listref of hashrefs).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает выборку (список хэшей).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_col',
		syn      => <<EOP,	
	my \@col = sql_select_col (&lt;&lt;EOS, ...);
		SELECT 
			id
		FROM 
			...
		WHERE 
			...
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first column of the resultset (list).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первый столбец выборки (список).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_array',
		syn      => <<EOP,	
	my \$r = sql_select_array (&lt;&lt;EOS, ...);
		SELECT 
			...
		FROM 
			...
		WHERE 
			id = ?
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first record of the resultset (array, not arrayref).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первую запись выборки (список, не по ссылке).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_scalar',
		syn      => <<EOP,	
	my \$label = sql_select_scalar (&lt;&lt;EOS, ...);
		SELECT 
			label
		FROM 
			...
		WHERE 
			id = ?
EOS
EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first field of the first record of the resultset (scalar).',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первое поле первой записи выборки (скаляр).',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_path',
		options  => [qw(id_param/id root)],
		syn      => <<EOP,	
	\$item -> {path} = sql_select_path ('rubrics', \$_REQUEST {id}, {
		id_param => 'parent',
		root     => {
			type => 'my_objects',
			name => 'All my objects',
			id   => ''			
		}
	});
EOP
		label_en => 'Fetches the path to the current object from the hierarchical (PREV id = parent) table in the form suitable for draw_path sub.',
		label_ru => 'Извлекает путь к текущей записи в иерархической (PREV id = parent) таблице в форме, пригодной для передачи процедуре draw_path.',
		see_also => [qw(draw_path sql_select_subtree)]
	},
	
					#######################################

	{
		name     => 'sql_select_subtree',
#		options  => [qw()],
		syn      => <<EOP,	
	my \@child_rubrics = sql_select_subtree ('rubrics', \$_REQUEST {id});
EOP
		label_en => 'Fetches all the child IDs from the hierarchical (PREV id = parent) table as an array.',
		label_ru => 'Извлекает все дочерние ID из иерархической (PREV id = parent) таблицы в виде массива',
		see_also => [qw(sql_select_path)]
	},

					#######################################

	{
		name     => 'sql_select_hash',
		syn      => <<EOP,	
				
	my \$r = sql_select_hash (&lt;&lt;EOS, $_REQUEST {id});
		SELECT 
			*
		FROM 
			users
		WHERE 
			id = ?
EOS

	my \$user = sql_select_hash ('users');

EOP
		label_en => 'Executes a given SQL (SELECT) statement with supplied parameters and returns the first record of the resultset (hashref). If all fields belong to the same table and the ID is $_REQUEST {id} then you can use the simplified form: only table name is supplied.',
		label_ru => 'Исполняет оператор SQL с заданными аргументами и возвращает первую запись выборки (хэш). Если в запросе участвует только 1 таблица, а ID совпадает с $_REQUEST {id}, то вместо SQL можно указать только имя таблицы.',
#		see_also => [qw()]
	},

					#######################################

	{
		name     => 'sql_select_vocabulary',
		syn      => <<EOP,	
	\$item -> {roles} = sql_select_vocabulary ('roles');
EOP
		label_en => 'Selects all records from a given table where fake=0 ordered by label ascending (data vocabulary).',
		label_ru => 'Выбирает из заданной таблицы все записи, для которых fake=0 в опрядке возрастания label (словарь данных).',
		see_also => [qw(add_vocabularies draw_form_field_radio draw_form_field_select)]
	},



					#######################################

	{
		name     => 'draw_centered_toolbar_button',
		options  => [qw(off href target/_self confirm onclick label)],
		label_en => 'Draws a button on a toolbar. Invoked from "draw_centered_toolbar" sub.',
		label_ru => 'Отрисовывает кнопку на панели снизу от формы ввода. Вызывается из-под "draw_centered_toolbar"',
		see_also => [qw(draw_centered_toolbar)]
	},


					#######################################

	{
		name     => 'draw_centered_toolbar',
		options  => [qw()],
		syn      => <<EO,
	draw_centered_toolbar ({}, [
		{
			icon => 'ok',     
			label => 'OK', 
			href => '#', 
			onclick => "document.form.submit()"
		},
		{
			icon => 'cancel', 
			label => 'Esc', 
			href => '/', 
			id => 'esc'
		},
	 ])		
EO
		label_en => 'Draws a toolbar on bottom of an input form. Usually you should use draw_ok_esc_toolbar instead.',
		label_ru => 'Отрисовывает панель снизу от формы ввода. Как правило, следует использовать draw_ok_esc_toolbar.',
		see_also => [qw(
			draw_form 
			draw_table
			draw_centered_toolbar_button
			draw_back_next_toolbar
			draw_close_toolbar
			draw_esc_toolbar
			draw_ok_esc_toolbar
		)]
	},

					#######################################

	{
		name     => 'draw_back_next_toolbar',
		options  => [qw(additional_buttons back)],
		label_en => 'Draws toolbar with Back and Next buttons. Used in wizards',
		label_ru => 'Отрисовывает панель с кнопками "назад" и "далее". Применяется для пошаговых "мастеров".',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_close_toolbar',
		options  => [qw(additional_buttons)],
		label_en => 'Draws toolbar with a close button. Used in popup windows.',
		label_ru => 'Отрисовывает панель с кнопкой "закрыть". Применяется для всплывающих окон.',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_esc_toolbar',
		options  => [qw(esc additional_buttons)],
		label_en => 'Draws toolbar with an escape button.',
		label_ru => 'Отрисовывает панель с кнопкой "выход"',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_ok_esc_toolbar',
		options  => [qw(name esc/?type=$_REQUEST{type} additional_buttons label_ok/применить label_cancel/вернуться)],
		label_en => 'Draws toolbar with an escape button.',
		label_ru => 'Отрисовывает панель с кнопкой "выход"',
		see_also => [qw(draw_centered_toolbar)]
	},

					#######################################

	{
		name     => 'draw_form',
		options  => [qw(action/update type/$_REQUEST{type} id/$_REQUEST{id} name/form target/invisible bottom_toolbar/draw_ok_esc_toolbar() no_ok keep_params)],
		syn      => <<EO,
		
	my \$data = {				# comes from 'get_item_of_users' callback sub
	
		id	 => 1,
		name     => 'J. Doe',
		login    => 'scott',
		password => 'tiger',
		id_role  => 1,
		
		path    => [		# passed to draw_path (see)
			{type => 'users', name => 'Everybody'},
			{type => 'users', name => 'J. Doe', id => 1},
		],
		
		roles    => [		# vocabulary
			{id => 1, name => 'admin'},
			{id => 2, name => 'user'},
		],
			
	};
		
	draw_form ({
			name => 'form1',
			esc  => '/?type=loosers&parent=13',
			additional_buttons => [
				{
					label => 'Disable it',
					href  => "/?type=users&action=disable&id=$$data{id}"
				}
			],
		}, 
		
		\$data
		
		[
			{			# text field -- by default
				name  => 'name',
				label => 'Name',
				size  => 30,
			},
			[			# 2 fields at one line
				{
					name  => 'login',
					mandatory  => 1,
					label => '&login',
					size  => 30,
				},
				{
					name  => 'password',
					label => 'Password',
					type  => 'password',
					size  => 30,
 				},
			],
			{			# drop-down
				name   => 'id_role',
				label  => 'Role',
				type   => 'select',
				values => \$data -> {roles},
			},
		]
	);
EO
		label_en => 'Draws the input form. Individual fields are rendered with "draw_form_field_$type" (default type is "string") subs, see references below. For each input $_, the "value" option defaults to $data -> {$_ -> {name}}. Options are passed to the bottom toolbar rendering subroutine (as usual, draw_ok_esc_toolbar).',
		label_ru => 'Отрисовывает форму ввода данных. Отдельные поля отрисовываются подпрограммами "draw_form_field_$type" (тип по умолчанию -- "string"), см. ссылки ниже. Для каждого поля ввода $_ опция "value" по умолчанию определяется как $data -> {$_ -> {name}}. Опции передаются подрпограмме отрисовки нижней панели с кнопками (обычно draw_ok_esc_toolbar)',
		see_also => [qw(
			draw_ok_esc_toolbar
			draw_form_field_button
			draw_form_field_datetime 
			draw_form_field_checkbox
			draw_form_field_checkboxes
			draw_form_field_file 
			draw_form_field_image
			draw_form_field_hgroup 
			draw_form_field_hidden
			draw_form_field_htmleditor
			draw_form_field_password
			draw_form_field_radio
			draw_form_field_select
			draw_form_field_static
			draw_form_field_string 
			draw_form_field_text
		)]
	},

					#######################################

	{
		name     => 'draw_form_field_button',
		options  => [qw(name label onclick)],
		label_en => 'Draws a button. Invoked by draw_form.',
		label_ru => 'Отрисовывает кнопку. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_htmleditor',
		options  => [qw(name label width height)],
		label_en => 'Draws the WYIWYG HTML editing area (see http://www.fredck.com/FCKeditor/). Invoked by draw_form.',
		label_ru => 'Отрисовывает интерактивный редактор HTML (см. http://www.fredck.com/FCKeditor/). Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_image',
		options  => [qw(name label id_image src width height new_image_url)],
		label_en => 'Draws the image with a button invoking a choose dialog box. Invoked by draw_form.',
		label_ru => 'Отрисовывает картинку и кнопку, вызвыающую диалог выбора нового изображения. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_select',
		options  => [qw(name label value values off empty max_len onChange height)],
		label_en => 'Draws the drop down listbox. Invoked by draw_form.',
		label_ru => 'Отрисовывает выпадающий список опций. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form sql_select_vocabulary)]
	},

					#######################################

	{
		name     => 'draw_form_field_checkboxes',
		options  => [qw(name label value values off)],
		label_en => 'Draws the group of checkboxes. Invoked by draw_form.',
		label_ru => 'Отрисовывает группу checkbox\'ов. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_checkbox',
		options  => [qw(name label checked off)],
		label_en => 'Draws the checkbox. Invoked by draw_form.',
		label_ru => 'Отрисовывает поле логигеского ввода (checkbox). Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_radio',
		options  => [qw(name label value values off)],
		label_en => 'Draws the group of radiobuttons. Invoked by draw_form.',
		label_ru => 'Отрисовывает группу радиокнопок. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form sql_select_vocabulary)]
	},

					#######################################

	{
		name     => 'draw_form_field_static',
		options  => [qw(name label value off href values hidden_name hidden_value)],
		label_en => 'Draws the static text in the place of the form input. Used to implement [temporary] read only fields. Invoked by draw_form.',
		label_ru => 'Отрисовывает статический текст на месте поля ввода. Изображает [временно] нередактируемое поле записи. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_password',
		options  => [qw(name label value off)],
		label_en => 'Draws the password form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает поле ввода пароля. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_text',
		options  => [qw(name label value off rows/25 cols/60)],
		label_en => 'Draws the textarea form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает многострочное текстовое поле ввода. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_hgroup',
		options  => [qw(items)],
		label_en => 'Draws the horizontal group of form inputs defined by "items" option. Invoked by draw_form.',
		label_ru => 'Отрисовывает строку полей ввода, описания которых заданы опцией "items". Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_file',
		options  => [qw(name label)],
		label_en => 'Draws the file upload form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает поле ввода для загрузки файла. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_hidden',
		options  => [qw(name value off)],
		label_en => 'Draws the hidden form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает скрытое поле ввода. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_string',
		options  => [qw(name label value off size max_len/$$conf{max_len} picture)],
		label_en => 'Draws the text form input. Invoked by draw_form.',
		label_ru => 'Отрисовывает текстовое поле ввода. Вызывается процедурой draw_form.',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_form_field_datetime',
		options  => [qw(name label value off format/$$conf{format_dt} no_time onClose)],
		label_en => 'Draws the calendar form input (DHTML from http://dynarch.com/mishoo/calendar.epl).',
		label_ru => 'Отрисовывает поле ввода типа "календарь" (DHTML-код позаимствован с http://dynarch.com/mishoo/calendar.epl).',
		see_also => [qw(draw_form)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_text',
		options  => [qw(name label value off keep_params)],
		syn      => <<EO,	
	draw_toolbar_input_text ({
		label  => 'Search',
		name   => 'q',
	}),
EO
		label_en => 'Draws the text input (usually, for quick search).',
		label_ru => 'Отрисовывает текстовое поле ввода на панели над таблицей (обычно для быстрого поиска).',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_select',
		options  => [qw(name values value empty)],
		syn      => <<EO,	
	draw_toolbar_input_select ({
		name   => 'id_topic',
		values => \$data -> {topics},
		empty  => '[All topics]',
	}),						
EO
		label_en => 'Draws the drop-down input (usually, for quick filter).',
		label_ru => 'Отрисовывает выпадающий список на панели над таблицей (обычно для быстрого фильтра).',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_input_checkbox',
		options  => [qw(name label)],
		syn      => <<EO,	
	draw_toolbar_input_checkbox ({
		name   => 'show_hidden',
		label  => 'Show hidden items',
	}),						
EO
		label_en => 'Draws the checkbox input (usually, for quick filter).',
		label_ru => 'Отрисовывает поле для галочки на панели над таблицей (обычно для быстрого фильтра).',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_toolbar_pager',
		options  => [qw(cnt total portion/$$conf{portion})],
		syn      => <<EO,	
	draw_toolbar_pager ({
		cnt     => 0 + @{$data -> {list}},
		total   => \$data -> {cnt},
		portion => \$data -> {portion},
	})
EO
		label_en => 'Draws the table navigation pager.',
		label_ru => 'Отрисовывает элемент листания таблицы.',
		see_also => [qw(draw_toolbar)]
	},

					#######################################

	{
		name     => 'draw_hr',
		options  => [qw(height/1 class/bgr8)],
		syn      => 'draw_hr (height => 10, class => "bgr0")',
		label_en => 'Draws a vertical spacer (mostly inter-table divider).',
		label_ru => 'Отрисовывает пустой межтабличный разделитель заданной высоты.',
	},


					#######################################

	{
		name     => 'draw_toolbar',
		options  => [qw(off target/invisible keep_params)],
		syn      => <<EO,	
	draw_toolbar (
	
		{
			off => \$_REQUEST {__read_only},
			keep_params => ['parent'],
		},
		
		draw_toolbar_button ({
			icon => 'create',
			label => 'Create',
			href => "?type=my_objects&action=create",
		}),

		draw_toolbar_input_text ({
			label  => 'Search',
			name   => 'q',
		}),
		
		draw_toolbar_pager ({
			cnt     => 0 + @{$data -> {list}},
			total   => \$data -> {cnt},
			portion => \$data -> {portion},
		})
		
	)
EO
		label_en => 'Draws the toolbar on top of the table.',
		label_ru => 'Отрисовывает панель с кнопками поверх таблицы.',
		see_also => [qw(draw_toolbar_button draw_toolbar_input_text draw_toolbar_input_select draw_toolbar_pager)]
	},

					#######################################

	{
		name     => 'draw_toolbar_button',
		options  => [qw(label href target/_self confirm off)],
		syn      => <<EO,	
	draw_toolbar_button ({
		icon => 'create',
		label => 'Create',
		href => "?type=my_objects&action=create",
	})
EO
		label_en => 'Draws a button on the toolbar on top of the table.',
		label_ru => 'Отрисовывает кнопку на панели поверх таблицы.',
		see_also => [qw(draw_toolbar)]
	},



					#######################################

	{
		name     => 'draw_window_title',
		options  => [qw(label off)],
		syn      => <<EO,	
	draw_window_title ({
		label => "My Fancy Window",
		off   => \$data -> {no_crap},
	})
EO
		label_en => 'Draws the window title.',
		label_ru => 'Отрисовывает заголовок окна.',
	},
	
					#######################################

	{
		name     => 'draw_path',
		options  => [qw(max_len multiline id_param/id)],
		see_also => [qw(sql_select_path)],
		syn      => <<EO,	
	draw_path ([
		{type => rubrics,  name => 'Contents'},
		{type => rubrics,  name => 'Rubric1',    id => 1,  id_param => 'id_rubric'},
		{type => rubrics,  name => 'Rubric2',    id => 2,  id_param => 'id_rubric'},
		{type => articles, name => 'My Article', id => 10},
	])
EO
		label_en => 'Draws the object path (like "Contents/Rubric1/Rubric2/My Article").',
		label_ru => 'Отрисовывает путь к объекту (например, "Contents/Rubric1/Rubric2/My Article").',
	},

					#######################################

	{
		name     => 'draw_text_cells',
		syn      => <<EO,	
	draw_text_cells ({href => "/?type=foo&action=bar"}, [
			'foo',
			'bar',
			{
				label   => "100000000",
				picture => '\$ ### ### ###',
			}
		])
EO
		label_en => 'Draws the series of text cells with common options.',
		label_ru => 'Отрисовывает последовательность текстовых клеток с общими опциями.',
		see_also => [qw(draw_table draw_text_cell)]
	},

					#######################################

	{
		name     => 'draw_row_buttons',
		options  => [qw(off)],
		syn      => <<EO,	
	draw_row_buttons ({off => 0 + NEVER + EVER}, [
			{
				label   => "[Edit]",
				icon    => "edit",
				href    => "/?type=items&id=\$\$i{id}",
			},
			{
				label   => "[Delete]",
				icon    => "delete",
				href    => "/?type=items&action=delete&id=\$\$i{id}",
				confirm => "Are you sure?!",
			}
		])
EO
		label_en => 'Draws the series of row buttons.',
		label_ru => 'Отрисовывает последовательность кнопок в строке таблицы.',
		see_also => [qw(draw_table draw_row_button)]
	},


					#######################################

	{
		name     => 'draw_text_cell',
		options  => [qw(label max_len/$$conf{max_len} picture attributes off href target/invisible a_class/lnk4)],
		syn      => <<EO,	
	draw_text_cell ('foo')

	draw_text_cell ({
		label   => "100000000",
		picture => '\$ ### ### ###',
		href    => "/?type=foo&action=bar",
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table draw_text_cells)]
	},

					#######################################

	{
		name     => 'draw_input_cell',
		options  => [qw(name label off/0 read_only/0 max_len/$$conf{max_len} size/30 attributes a_class/lnk4)],
		syn      => <<EO,	
	draw_input_cell ({
		name  => "_B5",
		label => \$i -> {B5},
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table)]
	},

					#######################################

	{
		name     => 'draw_checkbox_cell',
		options  => [qw(name value/1 attributes)],
		syn      => <<EO,	
	draw_checkbox_cell ({
		name  => "_adding_\$\$i{id}",
	})
EO
		label_en => 'Draws table cell containing an input field.',
		label_ru => 'Отрисовывает клетку таблицы с текстовым полем ввода.',
		see_also => [qw(draw_table)]
	},

					#######################################

	{
		name     => 'draw_row_button',
		options  => [qw(label icon href target/invisible confirm off)],
		syn      => <<EO,	
	draw_row_button ({
		label   => "[Delete]",
		icon    => "delete",
		href    => "/?type=items&action=delete&id=\$\$i{id}",
		confirm => "Are you sure?!",
	})
EO
		label_en => 'Draws a button in the table row.',
		label_ru => 'Отрисовывает кнопку в строке таблицы.',
		see_also => [qw(draw_table)]
	},

					#######################################

	{
		name     => 'draw_table',
		options  => [qw(off .. name type/$_REQUEST{type} action/add toolbar js_ok_escape)],
		syn      => <<EO,	
	draw_table (	
		
		['Name', 'Phone'],
		
		sub {
			draw_text_cell  ({ \$i -> {label} }),
			draw_input_cell ({ 
				name  => '_phone_' . \$i -> {id},
				label => \$i -> {phone},
			}),
		},
		
		[
			{id => 1, label => 'McFoo', phone => '001-01-01-001'},
			{id => 2, label => 'Dubar', phone => '0'},
		],
				
		{
			'..'    => 1,
			name    => 'form_phones',
			toolbar => draw_ok_esc_toolbar (),
		}		
	
	)
EO
		label_en => 'Draws the data table with the given headers, callback sub and data array. Data are passed to the callback sub through the global variable $i.',
		label_ru => 'Отрисовывает таблицу данных с заданными заголовками, callback-процедурой и массивом данных. Данные передаются в callback-процедуру через глобальную переменную $i.',
		see_also => [qw(draw_text_cells draw_text_cell draw_input_cell draw_checkbox_cell draw_row_button draw_row_buttons)]
	},

					#######################################


);

################################################################################

@params = (

	{
		name => 'type',
		label_en => 'Screen type for the current request. Determines (with id and action) what callbacks (e.g. "select_$type", "draw_item_of_$type", "do_$action_$type") are to be invoked.',
		label_ru => 'Текущий тип экрана. Определяет (совместно с id и action), какие подпрограммы (например, "select_$type", "draw_item_of_$type", "do_$action_$type") должны быть вызваны.',
		default => 'logon',
	},

	{
		name => 'action',
		label_en => 'Action name. If set, "validate_$action_$type" and "do_$action_$type" callbackcs are invoked, then the user is redirected to the URL with an empty action.',
		label_ru => 'Имя действия. Если задан, то вызываются подапрограммы "validate_$action_$type" и "do_$action_$type", после чего пользователь перенаправляется на URL с пустым action',
	},

	{
		name => '__include_js',
		label_en => 'ARRAYREF of names of custom javaScript files located in application_root/doc_root/i/.',
		label_ru => 'Ссылка на список дополнительных javaScript-файлов, расположенных в директории  application_root/doc_root/i/.',
		default => '[\'js\']',
	},

	{
		name => '__include_css',
		label_en => 'ARRAYREF of names of custom CSS files located in application_root/doc_root/i/.',
		label_ru => 'Ссылка на список дополнительных CSS-файлов, расположенных в директории  application_root/doc_root/i/.',
	},

	{
		name => 'keepalive',
		label_en => 'If set, extends the lifetime for the session which number is his value. Internal paramerter, not to be used in application developpment.',
		label_ru => 'Если задан, то продлевает время жизни сессии, чей номер совпадает с его значением. Внутренний параметр, не должен использоваться напрямую.',
	},

	{
		name => 'sid',
		label_en => 'Session ID. If set, determines the current session => current user, otherwise the client is redirecred to the logon screen (type=logon).',
		label_ru => 'Если задан, то определяет ID сессии => текущего пользователя, в противном случае клиент перенаправляется на входную форму (type=logon).',
	},

	{
		name => 'salt',
		label_en => 'Fake parameter with random values. Used for preventing browser from using local HTML cache.',
		label_ru => 'Фиктивный параметр со случайными значениями. Используется для предотвращения кэширования HTML на стороне клиента.',
	},

	{
		name => '_frame',
		label_en => 'Reserved for browsers not suppotring IFRAME tag.',
		label_ru => 'Зарезервировано для браузеров без поддержки тега IFRAME.',
	},

	{
		name => 'error',
		label_en => 'Error message text. Must not be set directly, it\'s calulated from "validate_$action_$type" return value.',
		label_ru => 'Текст сообщения об ошибке. Не должен задаваться явно, так как вычисляется на основе значения, возвращаемого подпрограммой "validate_$action_$type".',
	},

	{
		name => '__response_sent',
		label_en => 'If set, no "draw_$type" or "draw_item_of_$type" sub is called and no HTML is sent to the client.',
		label_ru => 'Если задан, то процедура "draw_$type" или "draw_item_of_$type" не вызывается и сгенерированный HTML не пересылается клиенту.',
	},

	{
		name => 'redirect_params',
		label_en => 'Set this parameter to Data::Dumper($some_hashref) if you want to restore %$some_hashref as %_REQUEST after the next logon. Normally must appear only at logon screen as a hidden input.',
		label_ru => 'Установите значение этого параметра в Data::Dumper($some_hashref), если хотите, чтобы %$some_hashref был восстановлен как %_REQUEST после следующего входа в систему. В норме должен присутствовать только на ворме входа в виде скрытого поля ввода.',
	},

	{
		name => 'id',
		label_en => 'If set, "get_item_of_$type" and "draw_item_of_$type" will be called instead of "select_$type" and "draw_$type".',
		label_ru => 'Если установлен, то "get_item_of_$type" и "draw_item_of_$type" будут вызваны вместо "select_$type" and "draw_$type".',
	},

	{
		name => 'dbf',
		label_en => 'Obsoleted by __response_sent.',
		label_ru => 'Атавизм. Следует использовать __response_sent.'
	},

	{
		name => 'xls',
		label_en => 'If set, the table with lpt attribute set to 1 is cropped from the output and sent to the client as an Excel worksheet.',
		label_ru => 'Если установлен, то из HTML страницы вызезается таблица с атрибутом lpt=1 и возвращается на клиент в виде рабочего листа Excel.'
	},

	{
		name => 'lpt',
		label_en => 'If set, the table with lpt attribute set to 1 is cropped from the output and sent to the client in the printer friendly form.',
		label_ru => 'Если установлен, то из HTML страницы вызезается таблица с атрибутом lpt=1 и возвращается на клиент в виде, пригодном для распечатки.'
	},
	
	{
		name => 'role',
		label_en => 'Current role ID. Used in multirole alpplications only.',
		label_ru => 'ID текущей роли. Имеет смысл только в приложениях, где один пользователь может работать в нескольких ролях.'
	},

	{
		name => 'order',
		label_en => 'Name of the sort column. Set in hrefs produced by headers sub, used in SQL generated by order sub.',
		label_ru => 'Имя столбца, по которому производится сортировка. Устанавливается в ссылках, сгенерироанных headers, используется в SQL, сгенерированном order.',
	},
	
	{
		name => 'desc',
		label_en => 'If true, the sort order is descending. Set in hrefs produced by headers sub, used in SQL generated by order sub.',
		label_ru => 'Если истина, то порядок сортировки обратный. Устанавливается в ссылках, сгенерироанных headers, используется в SQL, сгенерированном order.',
	},

	{
		name => '__content_type',
		label_en => 'MIME type of the HTTP responce sent to the client.',
		label_ru => 'MIME-тип HTTP-ответа',
		default => 'text/html; charset=windows-1251',
	},
	
	{
		name => 'period',
		label_en => 'Always tranferred by <a href=../check_href.html>check_href</a> sub. Reserved for calendar-like applications.',
		label_ru => 'Всегда передаётся по ссылкам через <a href=../check_href.html>check_href</a>. Зарезервировано для календарных приложений.',
	},
	
	{
		name => '__read_only',
		label_en => 'If true, all input fields are disabled.',
		label_ru => 'Если истина, все поля ввода превращаются в надписи.',
	},

	{
		name => '__pack',
		label_en => 'If true, the browser window is packed around the main form/table. Used in popup windows.',
		label_ru => 'Если истина, окно браузера сжимается до минимума, охватывающего страницу. Используется во всплывающих окнах.',
	},
	
	{
		name => '__popup',
		label_en => 'If true, set all of __read_only, __pack and __no_navigation to true.',
		label_ru => 'Если истина, то истинны также __read_only, __pack и __no_navigation.',
	},

	{
		name => '__no_navigation',
		label_en => 'If true, no top navigation bar (user name/calendar/logout) is shown. Used in popup windows.',
		label_ru => 'Если истина, то не показывается верняя панель навигации (пользователь/календарь/выход). Используется во всплывающих окнах.',
	},

	{
		name => '_xml',
		label_en => 'If set, is surrounded with XML tags and placed in HEAD section. Used for MS Office 2000 HTML emulation.',
		label_ru => 'Если непуст, то окружается тегами XML и помещается в раздел HEAD. Используется для эмуляции MS Office 2000 HTML.',
	},

	{
		name => '__scrollable_table_row',
		label_en => 'Numer of table row highlighted by the slider at page load.',
		label_ru => 'Номер строки таблицы, на которой располагается слайдер при загрузке страницы.',
		default => '0',
	},

	{
		name => '__meta_refresh',
		label_en => 'The value for &lt;META HTTP-EQUIV=Refresh ... &gt; tag.',
		label_ru => 'Значение для тега &lt;META HTTP-EQUIV=Refresh ... &gt;.',
	},
	
	{
		name => '__focused_input',
		label_en => 'The NAME of the input to be focused at page load. Unless set, the first text inpyt is focused.',
		label_ru => 'Значение атрибута NAME поля ввода, на котором должен стоять фокус ввода при загрузке страницы. Если не установлен, фокусируется первое текстовое поле.',
	},

	{
		name => '__blur_all',
		label_en => 'If true, no input is focused.',
		label_ru => 'Если установлен, ни одно поле ввода не имеет фокуса.',
	},

	{
		name => '__help_url',
		label_en => 'URL to be activated on F1 press or [Help] link.',
		label_ru => 'URL, активизируемый при нажатии на F1 или ссылку [Справка].',
	},

	{
		name => '__path',
		label_en => 'Set internally by <a href=../draw_path.html>draw_path</a> for implement \'..\' facility in <a href=../draw_table.html>draw_table</a>.',
		label_ru => 'Устанавливается внутри <a href=../draw_path.html>draw_path</a>, чтобы реализовать опцию \'..\' в <a href=../draw_table.html>draw_table</a>.',
	},

	{
		name => '__toolbars_number',
		label_en => 'Set internally by <a href=../draw_toolbar.html>draw_toolbar</a> for proper toolbar indexing.',
		label_ru => 'Устанавливается внутри <a href=../draw_toolbar.html>draw_toolbar</a> для индексации панелей управления.',
	},
	
	{
		name => 'start',
		label_en => 'Number of first displayed record in multipage recordsets.',
		label_ru => 'Номер первой записи выборки, показываемой на странице (при наличии нарезки).',
	},

);

################################################################################

%i18n = (
	NAME => {
		en => 'NAME',
		ru => 'НАЗВАНИЕ',
	},
	SYNOPSIS => {
		en => 'SYNOPSIS',
		ru => 'ИСПОЛЬЗОВАНИЕ',
	},
	DESCRIPTION => {
		en => 'DESCRIPTION',
		ru => 'ОПИСАНИЕ',
	},
	OPTIONS => {
		en => 'OPTIONS',
		ru => 'ОПЦИИ',
	},
	DEFAULT => {
		en => 'DEFAULT',
		ru => 'ПО УМОЛЧАНИЮ',
	},
	SEE_ALSO => {
		en => 'SEE ALSO',
		ru => 'СМ. ТАКЖЕ',
	},	
	DEFAULT => {
		en => 'DEFAULT VALUE',
		ru => 'ПО УМОЛЧАНИЮ',
	},	
	'API Reference' => {
		en => 'API Reference',
		ru => 'Подпрограммы',
	},
);

################################################################################

sub generate_param {

	my ($lang, $s) = @_;		
	
	my $see_also = '';
	foreach my $sa (sort @{$s -> {see_also}}) {
		$see_also .= qq{<li><a href="$sa.html">$sa</a>};
	}
	
	$see_also and $see_also = <<EOF;
					<dt>${$i18n{SEE_ALSO}}{$lang}
					<dd><ul>$see_also</ul>
EOF
		
	open (F, ">$lang/params/$$s{name}.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Zanas.pm documentation: parameter $$s{name}</TITLE>
				<link rel="STYLESHEET" href="../../css/z.css" type="text/css">
			</HEAD>
			<BODY>
				<dl>
					<dt>${$i18n{NAME}}{$lang}
					<dd>\$_REQUEST {$$s{name}}
					
					@{[ $$s{default} ? <<EOD : '' ]}
						<dt>${$i18n{DEFAULT}}{$lang}
						<pre>$$s{default}</pre>
EOD

					<dt>${$i18n{DESCRIPTION}}{$lang}
					<dd>$$s{"label_$lang"}
					
					$see_also

				</dl>
			</BODY>
		</HTML>
EOF

	close (F);

}

################################################################################

sub generate_sub {

	my ($lang, $s) = @_;
	
	my $options = '';
	foreach my $o (@{$s -> {options}}) {
		my ($name, $default) = split /\//, $o;
		$default ||= '&nbsp;';
		my ($o_def) = grep {$_ -> {name} eq $name} @options;
		$o_def or die "Option not defined: $name.\n";
		my $label = $o_def -> {"label_$lang"};
		$options .= qq{<tr bgcolor=white><td>$name<td>$label<td>$default};
	}
	
	$options and $options = <<EOF;
					<dt>${$i18n{OPTIONS}}{$lang}
					<dd>
						<br>
						<table cellspacing=0 cellpadding=0><tr><td bgcolor=002000>
							<table cellspacing=1 cellpadding=5>
								<tr bgcolor=white><th>${$i18n{NAME}}{$lang}<th>${$i18n{DESCRIPTION}}{$lang}<th nowrap>${$i18n{DEFAULT}}{$lang}
								$options
							</table>
						</table>
EOF
	
	my $see_also = '';
	foreach my $sa (sort @{$s -> {see_also}}) {
		$see_also .= qq{<li><a href="$sa.html">$sa</a>};
	}
	
	$see_also and $see_also = <<EOF;
					<dt>${$i18n{SEE_ALSO}}{$lang}
					<dd><ul>$see_also</ul>
EOF
	
	
	open (F, ">$lang/$$s{name}.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Zanas.pm documentation: $$s{name}</TITLE>
				<link rel="STYLESHEET" href="../css/z.css" type="text/css">
			</HEAD>
			<BODY>
				<dl>
					<dt>${$i18n{NAME}}{$lang}
					<dd>$$s{name}

					<dt>${$i18n{SYNOPSIS}}{$lang}
					<pre>$$s{syn}</pre>

					<dt>${$i18n{DESCRIPTION}}{$lang}
					<dd>$$s{"label_$lang"}
					
					$options
					$see_also

				</dl>
			</BODY>
		</HTML>
EOF

	close (F);

}

################################################################################

sub generate_left {
	
	my ($lang) = @_;
	
	my $subs = '';
	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @subs) {
		$subs .= qq{<a href="$$s{name}.html" target="main">$$s{name}</a><br>};
		generate_sub ($lang, $s);
	}
		
	my $params = '';
	foreach my $s (sort {$a -> {name} cmp $b -> {name}} @params) {
		$params .= qq{<a href="params/$$s{name}.html" target="main">$$s{name}</a><br>};
		generate_param ($lang, $s);
	}
		
	open (F, ">$lang/left.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Zanas.pm documentation</TITLE>
				<STYLE>
					body {
					    background: #FFFFFF;
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    font-weight: normal;
					    font-size: 11px;
    					};
					h1 {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    font-weight: bold;
					    font-size: 12px;
    					};
					a:link, a:visited, a:active {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    text-decoration: none;
					    color: #005050;
    					};
					a:hover {
					    font-family: Verdana, Arial, Helvetica, sans-serif;
					    text-decoration: underline;
					    color: #005050;
    					};
				</STYLE>
			</HEAD>			
			<BODY>
				@{[ map { <<EO } @langs ]}
					<a href="../$_/index.html" target="_top">$_</a>
EO
				<h1>${$i18n{'API Reference'}}{$lang}</h1>
				$subs

				<h1>%_REQUEST</h1>
				$params
			</BODY>
		</HTML>
EOF
	close (F);
}

################################################################################

sub generate_index {
	my ($lang) = @_;
	open (F, ">$lang/index.html");
	print F <<EOF;
		<HTML>
			<HEAD>
				<TITLE>Zanas.pm documentation</TITLE>
			</HEAD>
			<FRAMESET cols="300,*">
				<FRAME name="left" src="left.html" target="main">
				<FRAME name="main" src="about.html">
			</FRAMESET>
		</HTML>
EOF
	close (F);
}

################################################################################

sub generate_for_lang {
	my ($lang) = @_;
	mkdir $lang;
	mkdir "$lang/params";
	generate_index ($lang);
	generate_left  ($lang);
}

################################################################################

sub generate {
	map { generate_for_lang ($_) } @langs;
	mkdir 'css';
	open (F, ">css/z.css");
	print F <<EOF;
		body {
		    background: #FFFFFF;
    		};
		dt {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: bold;
		    font-size: 12pt;
		    margin-top: 10px;
    		};
		dd {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: normal;
		    font-size: 10pt;
		    margin-top: 5px;
    		};
		pre {
		    font-family: Courier New, Courier;
		    font-weight: normal;
		    font-size: 10pt;
		    color: #603060;
    		};
		th {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: bold;
		    font-size: 10pt;
    		};
		td {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    font-weight: normal;
		    font-size: 10pt;
    		};
		a:link, a:visited, a:active {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    text-decoration: none;
		    color: #005050;
    		};
		a:hover {
		    font-family: Verdana, Arial, Helvetica, sans-serif;
		    text-decoration: underline;
		    color: #005050;
    		};
EOF
	close (F);
}

1;
