override public function styleChanged(styleProp:String):void
{
	if ( initialized )
	{
		super.styleChanged( styleProp );
		
		switch ( styleProp )
		{
			case 'gridInterval' : _gridInterval = getStyle( styleProp );
				break;
			case 'minStep'      : _minStep = getStyle( styleProp );
				break;
		}
		
		invalidateDisplayList();	
	}
}

override public function stylesInitialized():void
{
	super.stylesInitialized();
	
	if ( getStyle( 'gridThicknes' )  === undefined ) setStyle( 'gridThicknes', 0.1 );
	if ( getStyle( 'gridColor' )     === undefined ) setStyle( 'gridColor', 0xffffff );
	if ( getStyle( 'gridAlpha' )     === undefined ) setStyle( 'gridAlpha', 0.5 );
	if ( getStyle( 'gridInterval' )  === undefined ) setStyle( 'gridInterval', 1 );
	if ( getStyle( 'minStep' )       === undefined ) setStyle( 'minStep', 40 );
	
	_gridInterval = getStyle( 'gridInterval' );
	_minStep      = getStyle( 'minStep' );
}