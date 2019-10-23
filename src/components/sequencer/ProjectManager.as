/**
 * Организует загрузку/сохранение проекта разными методами 
 */
package components.sequencer
{

	
	
	
	import com.audioengine.calculations.Calculation;
	import com.audioengine.core.AudioData;
	import com.audioengine.sequencer.events.SequencerEvent;
	import com.serialization.Serialize;
	
	import components.sequencer.clipboard.SampleClipboardRecord;
	import components.sequencer.controls.TrackControl;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.managers.history.History;
	
	public class ProjectManager extends EventDispatcher
	{
		/**
		 * Описание возможных текущих выполняемых операций 
		 */
		
		/**
		 * Ничего не происходит 
		 */		
		public static const NONE : int = 0;
		
		/**
		 * Идет процесс сохранения данных проекта в локальный файл 
		 */		
		public static const SAVE_TO_LOCAL_FILE : int = 5;
		
		/**
		 * Идет процесс загрузки проекта из локального файла
		 */		
		public static const LOAD_FROM_LOCAL_FILE : int = 10;
		
		/**
		 * Идет процесс сохранения проекта из облака 
		 */		
		public static const SAVE_TO_CLOUD : int = 15;
		
		/**
		 * Идет процесс загрузки проекта из облака 
		 */		
		public static const LOAD_FROM_CLOUD : int = 20;
		
		/**
		 * Идет импорт трека 
		 */		
		public static const MIXDOWN_TO_FILE : int = 30;
		
		/**
		 * Текущая выполняемая операция в данный момент 
		 */		
		private var _action : int = NONE;
		
		/**
		 * Описание текущей выполняемой операции/подоперации 
		 */		
		private var _description : String;
		
		/**
		 * Ссылка на VisualSequencer 
		 */		
		private var vs : VisualSequencer;
		
		/**
		 * Для сохранения/загрузки проекта на компьютере пользователя 
		 */		
		private var file : FileReference;
		
		/**
		 * Для загрузки проекта с сервера 
		 */		
		private var cloud : URLLoader;
		
		public function ProjectManager( vs : VisualSequencer )
		{
			super();
			this.vs = vs;
		}
		
		public function get action() : int
		{
			return _action;
		}
		
		public function get description() : String
		{
			return _description;
		}	
		
		private function setListenersForFileReference( file : FileReference ) : void
		{
			file.addEventListener( ProgressEvent.PROGRESS, onLocalFileProgress );
			file.addEventListener( Event.COMPLETE, onLocalFileComplete );
			file.addEventListener( Event.CANCEL, onLocalFileCancel );
			file.addEventListener( Event.SELECT, onLocalFileSelect );
			file.addEventListener( IOErrorEvent.IO_ERROR, onLocalFileIOError );
		}
		
		private function removeListenersForFileReference( file : FileReference ) : void
		{	
			file.removeEventListener( ProgressEvent.PROGRESS, onLocalFileProgress );
			file.removeEventListener( Event.COMPLETE, onLocalFileComplete );
			file.removeEventListener( Event.CANCEL, onLocalFileCancel );
			file.removeEventListener( Event.SELECT, onLocalFileSelect );
			file.removeEventListener( IOErrorEvent.IO_ERROR, onLocalFileIOError );
		}
		
		private function onLocalFileProgress( e : ProgressEvent ) : void
		{
			dispatchEvent( e );
		}
		
		private function onLocalFileComplete( e : Event ) : void
		{
			removeListenersForFileReference( file );
			
			if ( _action == SAVE_TO_LOCAL_FILE )
			{
				_action = NONE;
				dispatchEvent( e );
			}
			else if ( _action == LOAD_FROM_LOCAL_FILE )
			{	
				vs.clearAll();
				vs.validateProperties();
				deserialize( new XML( file.data.readUTFBytes( file.data.length ) ) );
				_action = NONE;
				dispatchEvent( new Event( Event.COMPLETE ) );
			}
			else if ( _action == MIXDOWN_TO_FILE )
			{
				_action = NONE;
				dispatchEvent( e );
			}	
			
			file = null;
		}
		
		private function onLocalFileCancel( e : Event ) : void
		{
			removeListenersForFileReference( file );
			file = null;
			_action = NONE;
			
			dispatchEvent( e );	
		}
		
		private function onLocalFileSelect( e : Event ) : void
		{
			if ( _action == LOAD_FROM_LOCAL_FILE )
			{	
				file.load();
			}
			
			dispatchEvent( e );
		}
		
		private function onLocalFileIOError( e : IOErrorEvent ) : void
		{	
			removeListenersForFileReference( file );
			file = null;
			_action = NONE;
			
			dispatchEvent( e );
		}
		
		/**
		 * Выполняет десериализацию файла загруженного проекта 
		 * @param xml
		 * 
		 */		
		private function deserialize( xml : XML ) : void
		{
			try
			{
				History.enabled = false;
				
				if ( xml.name() != 'project' )
				 throw new Error( "Can't found main tag project." );
				
				if ( xml.bpm != undefined )
				{
					vs.bpm = Serialize.toFloat( xml.bpm );
				}
				
				if ( xml.position != undefined )
				{	
					vs.position = Serialize.toFloat( xml.position );
				}
				
				if ( xml.duration != undefined )
				{
					vs.duration = Serialize.toFloat( xml.duration );
				}
				
				if ( xml.scale != undefined )
				{
					vs.scale = Serialize.toFloat( xml.scale );
				}
				
				if ( xml.TrackControlGroup_currentState != undefined )
				{
					vs.controls.currentState = xml.TrackControlGroup_currentState;
				}	
				
				if ( xml.loop != undefined )
				{	
					if ( ( xml.loop.start != undefined ) && ( xml.loop.end != undefined ) )
					 {
							vs.startPosition = Serialize.toFloat( xml.loop.start );
							vs.endPosition   = Serialize.toFloat( xml.loop.end );
							vs.loop          = true;
					 }
				}
				
				var numTracks          : int = 0;
				var sampleDescriptions : Vector.<SampleClipboardRecord> = new Vector.<SampleClipboardRecord>();
				
				if ( xml.channels != undefined )
				{
					var soloChannel : int = -1;
					
					if ( xml.channels.solo != undefined )
					{
					  soloChannel = Serialize.toInt( xml.channels.solo ); 	
					}	
					
					for each( var channel : XML in xml.channels.elements( 'channel' ) )
					{
					   if ( channel.notes != undefined )
					   {   
						   for each( var note : XML in channel.notes.elements( 'note' ) )
						   {
							  var record : SampleClipboardRecord = SampleClipboardRecord.deserializeFromXML( note );
							      record.trackNumber = numTracks;
								  //record.description = vs.seq.library.getDescription( record.sample_id ); //Это необходимо будет переделать под новую модель данных
							  
							  if ( record.description ) //Если в библиотеке есть такой семпл, если нету просто игнорируем
							  {	  
								  sampleDescriptions.push( record );   
							  }		  
						   }
					   }
					   
	                   var name   : String = ( channel.name != undefined   ) ? channel.name : null;
					   var type   : String = ( channel.type != undefined   ) ? channel.type : null;
					   var volume : Number = ( channel.volume != undefined ) ? Serialize.toFloat( channel.volume ) : 1.0;
					   var pan    : Number = ( channel.pan != undefined ) ? Serialize.toFloat( channel.pan ) : 0.0;
					   var mono   : Boolean = ( channel.mono != undefined ) ? Serialize.toBoolean( channel.mono ) : false;
					   
					   vs.createTrack( name, type );
					   vs.seq.mixer.setVolumeAt( numTracks, volume );
					   vs.seq.mixer.setPanAt( numTracks, pan );
					   vs.seq.mixer.setMonoAt( numTracks, mono );
					   
					   numTracks ++;
					}
					
					vs.seq.mixer.soloChannel = soloChannel;	
				}
				
				vs.validateProperties();
				
				if ( xml.selectedTrack != undefined )
				{
					vs.selectedTrack = Serialize.toInt( xml.selectedTrack );
				}
				
				if ( xml.hpos != undefined )
				{
					vs.timeline.horizontalScrollPosition = Serialize.toFloat( xml.hpos );
				}
				
				if ( xml.vpos != undefined )
				{	
					vs.timeline.verticalScrollPosition = Serialize.toFloat( xml.vpos );
				}
				
				if ( numTracks > 0 )
				{
					vs.timeline.addSamplesByDescriptions( sampleDescriptions );
				}
					
			}	
			catch( error : Error )
			{	
			  	dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, error.message, error.errorID ) );
			}
			finally
			{
				History.enabled = true;
			}	
		}	
		
		/**
		 * Сериализует все параметры проекта в XML файл 
		 * @return 
		 * 
		 */
		/*
		<project>
		<bpm>number</bpm>
		<position>number</position>
		<duration>number</duration>
		<scale></scale>
		<hpos></hpos>
		<vpos></vpos>
		<selectedTrack></selectedTrack>
		<TrackControlGroup_currentState></TrackControlGroup_currentState>
		<loop>
		<start>number</start>
		<end>number</end>
		</loop>
		
		<channels>
		 <solo>{number}</solo>
		<channel>
		<type></type>
		<name></name>
		<volume></volume>
		<pan></pan>
		<mono></mono>
		<notes>
		<note>
		<position>16665</position>
		<sample id="0">
		<loop>true/false</loop>
		<inverted>true/false</inverted>
		<duration>number</duration>
		<offset>number</offset>
		</sample>
		</note>
		</notes>
		</channel>
		</channels>
		</project>
		*/
		private function serializeToXML() : XML
		{	
			var str : String = '<?xml version="1.0" encoding="UTF-8"?>';
			    str += '<project>';
				
				str += '<bpm>' + vs.bpm + '</bpm>';
				str += '<position>' + vs.position + '</position>';
				str += '<duration>' + vs.duration + '</duration>';
				str += '<scale>' + vs.scale + '</scale>';
				str += '<hpos>' + vs.timeline.horizontalScrollPosition + '</hpos>';
				str += '<vpos>' + vs.timeline.verticalScrollPosition + '</vpos>';
				
				if ( vs.selectedTrack != -1 )
				{
					str += '<selectedTrack>' + vs.selectedTrack + '</selectedTrack>';
				}	
				
				str += '<TrackControlGroup_currentState>' + vs.controls.currentState + '</TrackControlGroup_currentState>';
				
				if ( vs.loop )
				{
					str += '<loop>';
					str += '<start>' + vs.startPosition.toString() + '</start>';
					str += '<end>' + vs.endPosition.toString() + '</end>';
					str += '</loop>';
				}	
				
				str += '<channels>';
				
				if ( vs.seq.mixer.soloChannel != -1 )
				{
					str += '<solo>' + vs.seq.mixer.soloChannel.toString() + '</solo>';
				}	
				
				var i : int = 0;
				
				while( i < vs.numTracks )
				{	
					var t : TrackControl = vs.controls.getTrackControlAt( i );
					
					str += '<channel>';
					//str += '<type>guitar</type>'
					//str += '<name>' + t.trackName + '</name>';	
					str += '<volume>' + vs.seq.mixer.getVolumeAt( i ).toString() + '</volume>';
					str += '<pan>' + vs.seq.mixer.getPanAt( i ).toString() + '</pan>';
					
					if ( vs.seq.mixer.getMonoAt( i ) )
					{	
						str += '<mono>true</mono>';
					}
					
					str += vs.seq.getChannelAt( i ).listNote.serializeToXML();
					str += '</channel>';
					
					i ++;
				}
				
				str += '</channels>';
				
				str += '</project>';
			
			return new XML( str ); 
		}
		
		/**
		 * Сохраняет проект в файл на компьютере пользователя, асинхронный метод
		 * Необходимо отслеживать сдедующие события
		 * open:Event — Dispatched when a download operation starts.
		 * progress:ProgressEvent — Dispatched periodically during the file download operation.
		 * complete:Event — Dispatched when the file download operation successfully completes.
		 * cancel:Event — Dispatched when the user dismisses the dialog box.
		 * select:Event — Dispatched when the user selects a file for download from the dialog box.
		 * ioError:IOErrorEvent — Dispatched if an input/output error occurs while the file is being read or transmitted. 
		 * 
		 */	
		public function saveToLocalFile() : void
		{
			file = new FileReference();
			file.save( serializeToXML(), Settings.DEFAULT_PROJECT_FILE_NAME );
			setListenersForFileReference( file );
			
			_action = SAVE_TO_LOCAL_FILE;
		}
		
		/**
		 * Загружает проект из локального файла, асинхронный метод
		 * Необходимо отслеживать сдедующие события
		 * open:Event — Dispatched when a download operation starts.
		 * progress:ProgressEvent — Dispatched periodically during the file download operation.
		 * complete:Event — Dispatched when the file download operation successfully completes.
		 * cancel:Event — Dispatched when the user dismisses the dialog box.
		 * select:Event — Dispatched when the user selects a file for download from the dialog box.
		 * ioError:IOErrorEvent — Dispatched if an input/output error occurs while the file is being read or transmitted. 
		 * 
		 */
		public function loadFromLocalFile() : void
		{	
			file = new FileReference();
			file.browse( [ new FileFilter( Settings.DEFAULT_PROJECT_NAME, '*' + Settings.EXTENSION_FOR_PROJECT ) ] );
			setListenersForFileReference( file );
			
			_action = LOAD_FROM_LOCAL_FILE;
		}
		
		public function loadFromCloud( url : String ) : void
		{
			cloud = new URLLoader( new URLRequest( url ) );
			cloud.addEventListener( Event.COMPLETE, loadedFromCloud );
			cloud.addEventListener( ProgressEvent.PROGRESS, onLocalFileProgress );
			_action = LOAD_FROM_CLOUD;
		}
		
		private function loadedFromCloud( e : Event ) : void
		{
			cloud.removeEventListener( Event.COMPLETE, loadedFromCloud );
			cloud.removeEventListener( ProgressEvent.PROGRESS, onLocalFileProgress );
			
			deserialize( new XML( cloud.data ) );
			
			_action = NONE;
			
			dispatchEvent( e );
		}	
		
		/**
		 * Экспортирует проект в локальный WAVE файл на компьютере пользователя  
		 * @param from - с какой позиции ( в фреймах )
		 * @param to   - по какую        ( в фреймах )
		 * @param samplingRate - частота дискретизации результирующего файла  
		 * @param bitsPerSample - бит в выборке результирующего файла
		 * @param numChannels - количество каналов в результирующем файле
		 * 
		 */				
		public function mixdownToWAVEFile( bitsPerSample : int = -1, numChannels : int = -1 ) : void
		{	
			/*dataLength = vs.seq.beginMixDown();
			buffer = new ByteArray();
			
			waveCoder = new WAVECoder();
			waveCoder.begin( dataLength, bitsPerSample, numChannels );
			
			timerID = setInterval( processMixDown, MIXDOWN_TIME );
			
			_action = MIXDOWN_TO_FILE;*/
		}
		
		public function saveFile() : void
		{
			/*file = new FileReference();
			
			file.save( waveCoder.output, 'output.wav' );
			setListenersForFileReference( file );
			
			trace( 'zz = ' + waveCoder.output.length );*/
		}	
	}
}