package handler
{
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import mx.core.FlexGlobals;
	
	import components.managers.PopUpManager;

	public class NetErrorHandler
	{
		private static const UPDATE_TIMEOUT : Number = 2000;
		
		/**
		 * Список каналов нуждающихся в востановлении 
		 */		
		private static const channels : Vector.<IChannel> = new Vector.<IChannel>();
		
		/**
		 * Идет процесс востановления 
		 */		
		private static var repairing : Boolean;
		
		/**
		 * Количество обработанных каналов во время операции востановления 
		 */		
		private static var numProcessedChannels : int;
		private static var numChannels : int;
		
		private static var dialog : RepairDialog;
		
		public static function processError( channel : IChannel ) : Boolean
		{
			if ( repairing )
			{
			  var i : int = 0;
			  
			  while( i < channels.length )
			  {
				  if ( channels[ i ] == channel )
				  {
					  setTimeout( updateChannel, UPDATE_TIMEOUT, channel, ErrorEvent.ERROR );
					  return true;
				  }
				  
				  i ++;
			  }
			  
			  channels.push( channel );
			}
			else
			{
				channels.push( channel );
				return showDialog();
			}
			
			return true;
		}
		
		private static function showDialog() : Boolean
		{
			if ( ! dialog )
			{
				tryToRepair();
				
				if ( ! FlexGlobals.topLevelApplication.stage )
					return false;
				
				dialog = new RepairDialog();
				
				PopUpManager.addPopUp( dialog, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( dialog );
			}
			
			return true;
		}
		
		private static function hideDialog() : void
		{
			if ( dialog )
			{
				PopUpManager.removePopUp( dialog );
				dialog = null;
			}
		}
			
		private static function tryToRepair() : void
		{
			repairing = true;
			numProcessedChannels = 0;
			numChannels = channels.length;
			
			for each( var channel : IChannel in channels )
			{
				channel.addListener( Event.COMPLETE, onComplete );
				channel.repair();
			}
		}
		
		private static function removeListeners( channel : IChannel ) : void
		{
			channel.removeListener( Event.COMPLETE, onComplete );
		}
		
		private static function onComplete( e : Event ) : void
		{
			updateChannel( IChannel( e.currentTarget ), e.type );
		}
		
		private static function updateChannel( channel : IChannel, type : String ) : void
		{
			removeListeners( channel );
			numProcessedChannels ++;
			
			if ( type == Event.COMPLETE )
			{
				var i : int = 0;
				
				while( i < channels.length )
				{
					if ( channels[ i ] == channel )
					{
						channels.splice( i, 1 );
						break;
					}
					i ++;
				}
			}
			
			if ( numProcessedChannels == numChannels )
			{
				if ( channels.length == 0 )
				{
					repairing = false;
					hideDialog();
				}
				else 
				{
					tryToRepair();
				}
			}
		}
	}
}