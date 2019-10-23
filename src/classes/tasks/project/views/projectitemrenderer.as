import com.audioengine.core.TimeConversion;
import com.utils.DateUtils;
import com.utils.TimeUtils;

override public function set data( value : Object ) : void
{
	super.data = value;
	
	mixName.text = data.name + ' / ' + Settings.getGenreDescription( data.genre ).label;
	toolTip = data.description;
	tempo.text = ' ' + data.tempo;
	time.text = ' ' + TimeUtils.formatSeconds3( TimeConversion.numSamplesToSeconds( data.duration ) ) + '  ';
	created.text = DateUtils.format( data.updated );
}

private function creationComplete() : void
{
	setStyle( 'toolTipTarget', icon );
}