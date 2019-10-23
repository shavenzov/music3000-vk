import com.audioengine.core.TimeConversion;
import com.utils.TimeUtils;

import flashx.textLayout.conversion.TextConverter;

private var _data : Object;
private var _dataChanged : Boolean;

public function get text():String
{
	return null;
}

public function set text(value:String):void
{
}

public function get data() : Object
{
	return _data;
}

public function set data( value : Object ) : void
{
	_data = value;
	_dataChanged = true;
	invalidateProperties();
}

override protected function commitProperties() : void
{
	super.commitProperties();
	
	if ( _dataChanged )
	{
		category.category = _data.category;
		sampleName.text = _data.name;
		author.text = _data.author;
		genre.text = Settings.getGenreDescription( _data.genre ).label + ' / ' + Settings.getCategoryDescription( _data.category ).label;
		tempo.text = _data.bpm;
		time.textFlow = TextConverter.importToFlow( TimeUtils.formatSeconds2( TimeConversion.numSamplesToSeconds( _data.duration ) ), TextConverter.TEXT_FIELD_HTML_FORMAT );
		
		if ( _data.key )
		{
			key.text = _data.key;
		}
		
		key.visible = key.includeInLayout = 
		keyIcon.visible = keyIcon.includeInLayout = _data.key != null;
		
		_dataChanged = false;
	}
}



