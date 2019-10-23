package components.sequencer.clipboard
{
	import classes.BaseDescription;
	import classes.PaletteSample;
	import classes.SamplesPalette;
	
	import com.serialization.IXMLDeserializable;
	import com.serialization.Serialize;

	public class SampleClipboardRecord
	{
		public var description : BaseDescription;
		
		public var name : String;
		public var trackNumber : int;
		public var position    : Number;
		public var duration: Number;
		public var offset      : Number;
		public var loop : Boolean;
		public var inverted : Boolean;
		
		public function SampleClipboardRecord( name : String, trackNumber : int, position : Number, duration : Number, offset : Number, description : BaseDescription, loop : Boolean, inverted : Boolean )
		{
		  this.name          = name; 
		  this.trackNumber   = trackNumber;
		  this.position      = position;
		  this.duration      = duration;
		  this.offset        = offset;
		  this.description   = description;
		  this.loop          = loop;
		  this.inverted      = inverted;
		}
		
		public function get sample_id() : String
		{
			return description.id;
		}
		
		public static function deserializeFromXML( xml : XML, palette : SamplesPalette ) : SampleClipboardRecord
		{
			/*
			<sample id="0">
			 <loop>true/false</loop>
			 <inverted>true/false</inverted>
			 <duration>number</duration>
			 <offset>number</offset>
			</sample>
			*/
			
			var position  : Number = 0.0;
			var duration  : Number = 0.0;
			var offset    : Number = 0.0;
			var sample_id : String;
			var loop      : Boolean = true;
			var inverted  : Boolean;
			
			if ( xml.name() != 'note' )
			 throw new Error( "Can't found required tag note." );
			
			if ( xml.position != undefined )
			{
				position = Serialize.toFloat( xml.position );
			}	
			
			if ( xml.sample == undefined )
			 throw new Error( "Can't found required tag sample." );
			
			if ( xml.sample.@id == undefined )
			 throw new Error( "Can't found required attribute id." );
			
			/*
			BaseDescription.correctSampleID
			коректируем идентификатор сэмпла, если используется идентификатор старой версии
			*/
			sample_id = BaseDescription.correctSampleID( xml.sample.@id );
			
			var pS : PaletteSample = palette.getSample( sample_id );
			
			if ( ! pS )
			{
				//throw new Error( "Can't found required sample with id=" + sample_id );
				return null;
			}
			
			if ( xml.sample.duration != undefined )
			{
				duration = Serialize.toFloat( xml.sample.duration );
			}
			
			if ( xml.sample.offset != undefined )
			{
				offset = Serialize.toFloat( xml.sample.offset );
			}
			
			if ( xml.sample.loop != undefined )
			{	
				loop = Serialize.toBoolean( xml.sample.loop );
			}
			
			if ( xml.sample.inverted != undefined )
			{
				inverted = Serialize.toBoolean( xml.sample.inverted );
			}
			
			return new SampleClipboardRecord( null, 0, position, duration, offset, pS.description, loop, inverted );
		}	
	}
}