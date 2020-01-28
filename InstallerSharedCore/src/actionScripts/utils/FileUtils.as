////////////////////////////////////////////////////////////////////////////////
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0 
// 
// Unless required by applicable law or agreed to in writing, software 
// distributed under the License is distributed on an "AS IS" BASIS, 
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and 
// limitations under the License
// 
// No warranty of merchantability or fitness of any kind. 
// Use this software at your own risk.
// 
////////////////////////////////////////////////////////////////////////////////
package actionScripts.utils
{
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	public class FileUtils
	{
		public static const DATA_FORMAT_STRING:String = "dataAsString";
		public static const DATA_FORMAT_BYTEARRAY:String = "dataAsByteArray";
		public static const IS_MACOS:Boolean = !NativeApplication.supportsSystemTrayIcon;
		
		private static var pathCheckingFile:File;
		
		/**
		 * Creating new File instance everytime
		 * to detect if exists could be expensive
		 */
		public static function isPathExists(value:String):Boolean
		{
			if (!pathCheckingFile) pathCheckingFile = new File();
			try {
				pathCheckingFile.nativePath = value;
			} catch (e:Error)
			{
				return false;
			}
			
			return pathCheckingFile.exists;
		}
		
		/**
		 * Creating new File instance everytime
		 * to detect if path is directory or file
		 */
		public static function isPathDirectory(value:String):Boolean
		{
			if (!pathCheckingFile) pathCheckingFile = new File();
			try {
				pathCheckingFile.nativePath = value;
			} catch (e:Error)
			{
				return false;
			}
			
			return pathCheckingFile.isDirectory;
		}
		
		/**
		 * Validate if a given file is
		 * text file or binary
		 */
		public static function isBinary(fileContent:String):Boolean
		{
			return (/[\x00-\x08\x0E-\x1F]/.test(fileContent));
		}
		
		/**
		 * Writes to file with data
		 * @required
		 * destination: File (save-destination)
		 * data: Object (String or ByteArray)
		 */
		public static function writeToFile(destination:File, data:Object):void
		{
			var fs:FileStream = new FileStream();
			fs.open(destination, FileMode.WRITE);
			if (data is XML) fs.writeUTFBytes((data as XML).toXMLString());
			else if (data is String) fs.writeUTFBytes(data as String);
			else if (data is ByteArray) fs.writeBytes(data as ByteArray);
			else 
			{
				trace("Error::Unknown data type on write.");
			}
			
			fs.close();
		}
		
		/**
		 * Writes to file with data asynchronously
		 * @required
		 * destination: File (save-destination)
		 * data: Object (String or ByteArray)
		 * successHandler: Function
		 * errorHandler: Function (attr:- 1. String)
		 */
		public static function writeToFileAsync(destination:File, data:Object, successHandler:Function=null, errorHandler:Function=null):void
		{
			var fs:FileStream = new FileStream();
			manageListeners(fs, true);
			fs.openAsync(destination, FileMode.WRITE);
			if (data is ByteArray) fs.writeBytes(data as ByteArray);
			else if (data is String) fs.writeUTFBytes(data as String);
			else if (data is XML) fs.writeUTFBytes((data as XML).toXMLString());
			else 
			{
				manageListeners(fs, false);
				if (errorHandler != null) errorHandler("Error::Unknown data type on write.");
				return;
			}
			
			/*
			 * @local
			 */
			function onFileWriteProgress(event:OutputProgressEvent):void
			{
				if (event.bytesPending == 0)
				{
					manageListeners(event.target as FileStream, false);
					if (successHandler != null) successHandler();
				}
			}
			function handleFSError(event:IOErrorEvent):void
			{
				manageListeners(event.target as FileStream, false);
				if (errorHandler != null) errorHandler(event.text);
			}
			function manageListeners(origin:FileStream, attach:Boolean):void
			{
				if (attach)
				{
					origin.addEventListener(IOErrorEvent.IO_ERROR, handleFSError);
					origin.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onFileWriteProgress);
				}
				else
				{
					origin.close();
					origin.removeEventListener(IOErrorEvent.IO_ERROR, handleFSError);
					origin.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onFileWriteProgress);
				}
			}
		}
		
		/**
		 * Simple read to a given file/path
		 * @required
		 * target: File (read-destination)
		 * dataFormat: String (return data type after read)
		 * @return
		 * Object
		 */
		public static function readFromFile(target:File, dataFormat:String=DATA_FORMAT_STRING):Object
		{
			var loadedBytes:ByteArray;
			var loadedString:String;
			var fs:FileStream = new FileStream();
			fs.open(target, FileMode.READ);
			if (dataFormat == DATA_FORMAT_STRING) loadedString = fs.readUTFBytes(fs.bytesAvailable);
			else 
			{
				loadedBytes = new ByteArray();
				fs.readBytes(loadedBytes);
			}
			fs.close();
			
			return (loadedString || loadedBytes);
		}
		
		/**
		 * Reads from file asynchronously
		 * @required
		 * target: File (read-destination)
		 * dataFormat: String (return data type after read)
		 * successHandler: Function (attr:- 1. String or ByteArray)
		 * errorHandler: Function (attr:- 1. String)
		 */
		public static function readFromFileAsync(target:File, dataFormat:String=DATA_FORMAT_STRING, successHandler:Function=null, errorHandler:Function=null):void
		{
			var fs:FileStream = new FileStream();
			manageListeners(fs, true);
			fs.openAsync(target, FileMode.READ);
			
			/*
			 * @local
			 */
			function onOutputProgress(event:ProgressEvent):void
			{
				if (event.bytesTotal == event.bytesLoaded)
				{
					var loadedBytes:ByteArray;
					var loadedString:String;
					if (dataFormat == DATA_FORMAT_STRING) loadedString = event.target.readUTFBytes(event.target.bytesAvailable);
					else 
					{
						loadedBytes = new ByteArray();
						event.target.readBytes(loadedBytes);
					}
					
					manageListeners(event.target as FileStream, false);
					if (successHandler != null) successHandler(loadedBytes || loadedString);
				}
			}
			function onIOErrorReadChannel(event:IOErrorEvent):void
			{
				manageListeners(event.target as FileStream, false);
				if (errorHandler != null) errorHandler(event.text);
			}
			function onFileReadCompletes(event:Event):void
			{
				// this generally fires when a file has
				// no content thus no progressEvent will fire
				manageListeners(event.target as FileStream, false);
				if (successHandler != null) successHandler("");
			}
			function manageListeners(origin:FileStream, attach:Boolean):void
			{
				if (attach)
				{
					origin.addEventListener(ProgressEvent.PROGRESS, onOutputProgress);
					origin.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorReadChannel);
					origin.addEventListener(Event.COMPLETE, onFileReadCompletes);
				}
				else
				{
					origin.close();
					origin.removeEventListener(ProgressEvent.PROGRESS, onOutputProgress);
					origin.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorReadChannel);
					origin.removeEventListener(Event.COMPLETE, onFileReadCompletes);
				}
			}
		}
		
		/**
		 * Move files asynchronously
		 * @required
		 * source: File (folder-destination)
		 * target: File (folder-destination)
		 * successHandler: Function
		 * errorHandler: Function (attr:- 1. String)
		 */
		public static function moveFolderToDestinationFolderAsync(source:File, target:File, successHandler:Function=null, errorHandler:Function=null, moveFromSpecificPath:String=null):void
		{
			// probable termination
			if (!source.isDirectory || !target.isDirectory) return;
			
			var tmpRelativeSplit:Array;
			var tmpRelativePath:String;
			var isMoveSpecificPathFound:Boolean;
			var isSpecificPathMoved:Boolean;
			var sourceFiles:Array;
			
			if (moveFromSpecificPath)
			{
				var movePath:File = source.resolvePath(moveFromSpecificPath);
				if (movePath.exists)
				{
					sourceFiles = movePath.getDirectoryListing();
					keepMoving();
				}
				else if (errorHandler != null)
				{
					errorHandler("Move from specific path/directory does not exists");
				}
			}
			else if (!moveFromSpecificPath)
			{
				sourceFiles = source.getDirectoryListing();
				keepMoving();
			}
			
			/*
			* @local
			*/
			function keepMoving():void
			{
				if (sourceFiles.length != 0)
				{
					tmpRelativeSplit = target.getRelativePath(sourceFiles[0]).split("/");
					if (tmpRelativeSplit.length > 1) tmpRelativeSplit.shift();
					tmpRelativePath = tmpRelativeSplit.join("/");
					
					if (moveFromSpecificPath) tmpRelativePath = tmpRelativePath.replace(moveFromSpecificPath +"/", "")
					
					sourceFiles[0].moveToAsync(target.resolvePath(tmpRelativePath), true);
					manageListeners(sourceFiles[0] as File, true);
					sourceFiles.shift();
				}
				else
				{
					try
					{
						source.deleteDirectory(true);
					}
					catch (e:Error)
					{
						try { source.deleteDirectoryAsync(true); } catch (e2:Error){}
					}
					if (successHandler != null) successHandler();
				}
			}
			function fileMoveCompleteHandler(event:Event):void
			{
				manageListeners(event.target as File, false);
				keepMoving();
			}
			function onIOErrorMove(event:IOErrorEvent):void
			{
				manageListeners(event.target as File, false);
				if (errorHandler != null) errorHandler(event.text);
			}
			function manageListeners(origin:File, attach:Boolean):void
			{
				if (attach)
				{
					origin.addEventListener(Event.COMPLETE, fileMoveCompleteHandler);
					origin.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorMove);
				}
				else
				{
					origin.removeEventListener(Event.COMPLETE, fileMoveCompleteHandler);
					origin.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorMove);
				}
			}
		}
		
		/**
		 * Determines if given path is abolute or relative
		 * @required
		 * (path)value: String
		 * @return
		 * BOOL
		 */
		public static function isRelativePath(value:String):Boolean
		{
			var searchRegExp:RegExp = IS_MACOS ? new RegExp("~/.*.$", "i") : new RegExp(".*:\\|\/", "i");
			var results:Array = searchRegExp.exec(value);
			if (results != null) return false;
				
			// same for either platforms
			var tmpFirstChar:String = value.charAt(0);
			if (tmpFirstChar == "/" || tmpFirstChar == "\\") return false;
			
			// almost everything else
			return true;
		}
		
		/**
		 * Returns and validate an absolute or
		 * relative file system path
		 * @required
		 * path: String
		 * @optional
		 * relativeFromPath: File
		 * @return
		 * File
		 */
		public static function convertIfRelativeToAbsolute(path:String, relativeFromPath:File=null):File
		{
			var tmpFile:File;
			if (FileUtils.isRelativePath(path) && relativeFromPath)
			{
				try
				{
					// convert to abolute path to use with File API
					tmpFile = relativeFromPath.resolvePath(path);
					return tmpFile;
				}
				catch (e:Error)
				{
					// if any bad data to treat as File
					throw new Error("Unable to validate as file path: "+ path);
					return null;
				}
			}
			
			return convertToFile(path);
		}
		
		/**
		 * Copying source to destination
		 */
		public static function copyFile(from:File, to:File, overwrite:Boolean=false):void
		{
			try
			{
				from.copyTo(to, overwrite);
			}
			catch (e:Error)
			{
				from.copyToAsync(to, overwrite);
			}
		}
		
		/**
		 * Replace all the backslash to front-slashes
		 * in a given path value
		 */
		public static function normalizePath(path:String):String
		{
			if (path.indexOf("\\") != -1)
			{
				path = path.replace(/\\/g, "/");
			}
			return path;
		}
		
		/**
		 * Delete a directory async
		 */
		public static function deleteDirectoryAsync(directory:File, successHandler:Function=null, errorHandler:Function=null):void
		{
			manageListeners(directory, true) 
			directory.deleteDirectoryAsync(true);
			
			/*
			 * @local
			 */
			function completeHandlerDeletion(event:Event):void
			{
				manageListeners(event.target as File, false);
				if (successHandler != null) successHandler();
			}
			function onIOErrorDeletion(event:IOErrorEvent):void
			{
				manageListeners(event.target as File, false);
				if (errorHandler != null) errorHandler(event.text);
			}
			function manageListeners(origin:File, attach:Boolean):void
			{
				if (attach)
				{
					origin.addEventListener(Event.COMPLETE, completeHandlerDeletion);
					origin.addEventListener(IOErrorEvent.IO_ERROR, onIOErrorDeletion);
				}
				else
				{
					origin.removeEventListener(Event.COMPLETE, completeHandlerDeletion);
					origin.removeEventListener(IOErrorEvent.IO_ERROR, onIOErrorDeletion);
				}
			}
		}
		
		private static function convertToFile(path:String):File
		{
			try
			{
				var tmpFile:File = new File(path);
				return tmpFile;
			}
			catch (e:Error)
			{
				// if any bad data to treat as File
				throw new Error("Unable to validate as file path: "+ path);
			}
			
			return null;
		}
	}
}