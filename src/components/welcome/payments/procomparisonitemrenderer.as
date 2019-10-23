import flashx.textLayout.conversion.TextConverter;

override public function set data( value : Object ) : void
{
	super.data = value;
	
	icon.source = data.icon;
	feature.textFlow = TextConverter.importToFlow( data.feature, TextConverter.TEXT_FIELD_HTML_FORMAT );
	
	if ( data.basicTooltip != undefined )
	{
		basic.toolTip = data.basicToolTip;
	}
	
	basic.textFlow = TextConverter.importToFlow( data.basic, TextConverter.TEXT_FIELD_HTML_FORMAT );
	
	if ( data.proTooltip != undefined )
	{
		pro.toolTip = data.proTooltip;
	}
	
	pro.textFlow = TextConverter.importToFlow( data.pro, TextConverter.TEXT_FIELD_HTML_FORMAT );
	
}