override public function set data( value : Object ) : void
{
	super.data = value;
	
	mixName.text = data.name + ' / ' + Settings.getGenreDescription( data.genre ).label;
    toolTip = data.description;
}

private function creationComplete() : void
{
	setStyle( 'toolTipTarget', icon );
}