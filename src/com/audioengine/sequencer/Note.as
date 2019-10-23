package com.audioengine.sequencer
{
	import com.serialization.IXMLSerializable;
	import com.audioengine.core.IAudioData;
	import com.audioengine.core.TimeConversion;
	import com.audioengine.sequencer.events.SequencerEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class Note extends EventDispatcher implements IXMLSerializable
	{
		/**
		 * Источник данных ноты 
		 */		
		private var _source : IAudioData;
		
		/**
		 * положение ноты в фреймах
		 */		
		private var _start  : Number;
		
		/**
		 * Положение ноты в секундах 
		 */		
		private var _startTime : Number;
		
		public function Note( start : Number, source : IAudioData )
		{
		  _start  = start;
		  _source = source;
		}
		
		public function get source() : IAudioData
		{
			return _source;
		}
		
		public function get start() : Number
		{
			return _start;
		}
		
		public function set start( value : Number ) : void
		{
			_start = value;
			_startTime = TimeConversion.numSamplesToSeconds( _start );
			
			dispatchEvent( new SequencerEvent( SequencerEvent.SAMPLE_CHANGE ) );
		}
		
		public function get end() : Number
		{
		  return _start + _source.length;	
		}
		
		public function get length() : Number
		{
			return _source.length;
		}	
		
		public function get startTime() : Number
		{
			return _startTime;
		}
		
		public function set startTime( value : Number ) : void
		{
			_start = TimeConversion.secondsToNumSamples( value );
		}
		
		public function get endTime() : Number
		{
			return TimeConversion.numSamplesToSeconds( end );
		}
		
		public function clone() : Note
		{
			return ( _source as AudioLoop ) ? new Note( _start, _source.clone() ) : new Note( _start, _source );
		}
		
		public function serializeToXML() : String
		{
			/*
			<note>
			<position>16665</position>
			<sample id="0">
			<loop>true/false</loop>
			<inverted>true/false</inverted>
			<length>number</length>
			<offset>number</offset>
			</sample>
			</note>
			*/
			
			var str : String = '';
			
			str += '<note>';
			 str += '<position>' + _start.toString() + '</position>';
			 
			 var s : IXMLSerializable = _source as IXMLSerializable;
			 
			 if ( s )
			 {	 
				 str += s.serializeToXML();
			 }
			 
			str += '</note>';
			
			return new XML( str );
		}	
	}
}