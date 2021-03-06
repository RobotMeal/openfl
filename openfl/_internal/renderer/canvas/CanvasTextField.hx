package openfl._internal.renderer.canvas;

import openfl._internal.renderer.RenderSession;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.display.Graphics;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.ByteArray;

#if (js && html5)
import js.html.CanvasRenderingContext2D;
import js.Browser;
import js.html.ImageData;
#end

@:access(openfl.text.TextField)
@:access(openfl.display.Graphics)	

class CanvasTextField {
	
	
	#if (js && html5)
	private static var context:CanvasRenderingContext2D;
	#end
	
	
	public static inline function render (textField:TextField, renderSession:RenderSession):Void {
		
		#if (js && html5)
		
		if (!textField.__renderable || textField.__worldAlpha <= 0) return;
		
		update (textField);
		
		if (textField.__graphics.__canvas != null) {
			
			var context = renderSession.context;
			
			context.globalAlpha = textField.__worldAlpha;
			var transform = textField.__worldTransform;
			var scrollRect = textField.scrollRect;
			
			if (renderSession.roundPixels) {
			
				context.setTransform (transform.a, transform.b, transform.c, transform.d, Std.int (transform.tx), Std.int (transform.ty));
				
			} else {
				
				context.setTransform (transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty);
				
			}
			
			context.scale( 1 / textField.scaleX, 1 / textField.scaleY );
						
			if (scrollRect == null) {
				
				context.drawImage (textField.__graphics.__canvas, 0, 0);
				
			} else {
				
				context.drawImage (textField.__graphics.__canvas, scrollRect.x, scrollRect.y, scrollRect.width, scrollRect.height, scrollRect.x, scrollRect.y, scrollRect.width, scrollRect.height);
				
			}
			
		}
		
		#end
		
	}
	
	
	private static inline function renderText (textField:TextField, text:String, format:TextFormat, offsetX:Float, bounds:Rectangle ):Void {
		
		#if (js && html5)
		
		context.font = textField.__getFont (format);		
		context.fillStyle = "#" + StringTools.hex (format.color, 6);
		context.textBaseline = "top";
		
		var yOffset = 0.0;
		
		// Hack, baseline "top" is not consistent across browsers
		
		if (~/(iPad|iPhone|iPod|Firefox)/g.match (Browser.window.navigator.userAgent)) {
			
			yOffset = format.size * 0.185;
			
		}
		
		var lines = [];
		
		if (textField.wordWrap) {
			
			var words = text.split (" ");
			var line = "";
			
			var word, newLineIndex, test;
			
			for (i in 0...words.length) {
				
				word = words[i];
				newLineIndex = word.indexOf ("\n");
				
				if (newLineIndex > -1) {
					
					while (newLineIndex > -1) {
						
						test = line + word.substring (0, newLineIndex) + " ";
						
						if (context.measureText (test).width > textField.__width - 4 && i > 0) {
							
							lines.push (line);
							lines.push (word.substring (0, newLineIndex));
							
						} else {
							
							lines.push (line + word.substring (0, newLineIndex));
							
						}
						
						word = word.substr (newLineIndex + 1);
						newLineIndex = word.indexOf ("\n");
						line = "";
						
					}
					
					if (word != "") {
						
						line = word + " ";
						
					}
					
				} else {
					
					test = line + words[i] + " ";
					
					if (context.measureText (test).width > textField.__width - 4 && i > 0) {
						
						lines.push (line);
						line = words[i] + " ";
						
					} else {
						
						line = test;
						
					}
					
				}
				
			}
			
			if (line != "") {
				
				lines.push (line);
				
			}
			
		} else {
			
			lines = text.split ("\n");
			
		}

		for (line in lines) {
			
			switch (format.align) {
				
				case TextFormatAlign.CENTER:
					
					context.textAlign = "center";
					context.fillText (line, offsetX + textField.width / 2, 2 + yOffset, textField.textWidth );
					
				case TextFormatAlign.RIGHT:
					
					context.textAlign = "end";
					context.fillText (line, offsetX + textField.width - 2, 2 + yOffset, textField.textWidth );
					
				default:
					
					context.textAlign = "start";
					context.fillText (line, 2 + offsetX, 2 + yOffset, textField.textWidth );
					
			}
			
			yOffset += format.size * 1.185 + format.leading;
			
		}
		
		#end
		
	}
	
	
	public static function update (textField:TextField):Bool {
		
		#if (js && html5)
		
		var bounds = textField.getBounds( null );
		
		if (textField.__dirty) {
			
			if (((textField.__text == null || textField.__text == "") && !textField.background && !textField.border && !textField.__hasFocus) || ((textField.width <= 0 || textField.height <= 0) && textField.autoSize != TextFieldAutoSize.NONE)) {
				
				textField.__graphics.__canvas = null;
				textField.__graphics.__context = null;
				textField.__dirty = false;
				
			} else {
				
				if ( textField.__graphics == null || textField.__graphics.__canvas == null) {
					
					if ( textField.__graphics == null )
						textField.__graphics = new Graphics();
					
					textField.__graphics.__canvas = cast Browser.document.createElement ("canvas");
					textField.__graphics.__context = textField.__graphics.__canvas.getContext ("2d");
			
					textField.__graphics.__bounds = new Rectangle( 0, 0, bounds.width, bounds.height );
			
				}
				
				context = textField.__graphics.__context;
				
				if ((textField.__text != null && textField.__text != "") || textField.__hasFocus) {
					
					var text = textField.text;
					
					if (textField.displayAsPassword) {
						
						var length = text.length;
						var mask = "";
						
						for (i in 0...length) {
							
							mask += "*";
							
						}
						
						text = mask;
						
					}
					
					var measurements = textField.__measureText ();
					
					textField.__graphics.__canvas.width = Math.ceil (bounds.width);
					textField.__graphics.__canvas.height = Math.ceil (bounds.height);
					
					if (textField.border || textField.background) {
						
						textField.__graphics.__context.rect (0.5, 0.5, textField.width - 1, textField.height - 1);
						
						if (textField.background) {
							
							context.fillStyle = "#" + StringTools.hex (textField.backgroundColor, 6);
							context.fill ();
							
						}
						
						if (textField.border) {
							
							context.lineWidth = 1;
							context.strokeStyle = "#" + StringTools.hex (textField.borderColor, 6);
							context.stroke ();
							
						}
						
					}
					
					if (textField.__hasFocus && (textField.__selectionStart == textField.__cursorPosition) && textField.__showCursor) {
						
						var cursorOffset = textField.__getTextWidth (text.substring (0, textField.__cursorPosition)) + 3;
						context.fillStyle = "#" + StringTools.hex (textField.__textFormat.color, 6);
						context.fillRect (cursorOffset, 5, 1, (textField.__textFormat.size * 1.185) - 4);
						
					} else if (textField.__hasFocus && (Math.abs (textField.__selectionStart - textField.__cursorPosition)) > 0) {
						
						var lowPos = Std.int (Math.min (textField.__selectionStart, textField.__cursorPosition));
						var highPos = Std.int (Math.max (textField.__selectionStart, textField.__cursorPosition));
						var xPos = textField.__getTextWidth (text.substring (0, lowPos)) + 2;
						var widthPos = textField.__getTextWidth (text.substring (lowPos, highPos));
						
						// TODO: White text
						
						context.fillStyle = "#000000";
						context.fillRect (xPos, 5, widthPos, (textField.__textFormat.size * 1.185) - 4);
						
					}
					
					if (textField.__ranges == null) {
						
						renderText (textField, text, textField.__textFormat, 0, bounds );
						
					} else {
						
						var currentIndex = 0;
						var range;
						var offsetX = 0.0;
						
						for (i in 0...textField.__ranges.length) {
							
							range = textField.__ranges[i];
							
							renderText (textField, text.substring (range.start, range.end), range.format, offsetX, bounds );
							offsetX += measurements[i];
							
						}
						
					}
					
				} else {
												
					textField.__graphics.__canvas.width = Math.ceil (bounds.width);
					textField.__graphics.__canvas.height = Math.ceil (bounds.height);
					
					if (textField.border || textField.background) {
						
						if (textField.border) {
							
							context.rect (0.5, 0.5, textField.width - 1, textField.height - 1);
							
						} else {
							
							textField.__graphics.__context.rect (0, 0, textField.width, textField.height);
							
						}
						
						if (textField.background) {
							
							context.fillStyle = "#" + StringTools.hex (textField.backgroundColor, 6);
							context.fill ();
							
						}
						
						if (textField.border) {
							
							context.lineWidth = 1;
							context.lineCap = "square";
							context.strokeStyle = "#" + StringTools.hex (textField.borderColor, 6);
							context.stroke ();
							
						}
						
					}
					
				}
				
				textField.__graphics.__bitmap = BitmapData.fromCanvas( textField.__graphics.__canvas );
				
				textField.__dirty = false;
				return true;
				
			}
			
		}
		
		#end
		
		return false;
		
	}
	
	
}