################################################################################

sub Unsupported_draw_page {
	
	return <<EOH;
		<html>
			<head>
				<title>$$conf{page_title}</title>
				<LINK href="/i/new.css" type=text/css rel=STYLESHEET>
			</head>
			<body bgcolor=white leftMargin=0 topMargin=0 marginwidth="0" marginheight="0">
				<center>
					<p>&nbsp;
					<p>&nbsp;
					<p>&nbsp;
					<p>&nbsp;
					<p>&nbsp;
					<p>&nbsp;
					Извините, ваш браузер не поддерживается.
				</center>				
			</body>
		</html>
EOH
	
}

1;
