(*
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * This is a part of the Pascal port of ffmpeg.
 * - Changes and updates by the UltraStar Deluxe Team
 *
 * Conversion of libavutil/error.h
 * avutil version 52.38.100
 *
 *)

(**
 * @file
 * error code definitions
 *)

(**
 * @addtogroup lavu_error
 *
 * @
 *)

{* error handling *}

const
  ENOENT = 2;
  EIO    = 5;
  ENOMEM = 12;
  EINVAL = 22;
  EPIPE  = 32;  // just an assumption. needs to be checked.
  EDOM   = 33;
  {$IFDEF MSWINDOWS}
  // Note: we assume that ffmpeg was compiled with MinGW.
  // This must be changed if DLLs were compiled with cygwin.
  ENOSYS = 40;  // MSVC/MINGW: 40, CYGWIN: 88,  LINUX/FPC: 38
  EILSEQ = 42;  // MSVC/MINGW: 42, CYGWIN: 138, LINUX/FPC: 84
  {$ENDIF}

(**
 * We need the sign of the error, because some platforms have 
 * E* and errno already negated. The previous version failed
 * with Delphi, because it needed EINVAL defined.
 * Warning: This code is platform dependent and assumes constants 
 * to be 32 bit.
 * This version does the following steps:
 * 1) shr 30:        shifts the sign bit to bit position 2
 * 2) and $00000002: sets all other bits to zero
 *                   positive EINVAL gives 0, negative gives 2
 * 3) - 1:           positive EINVAL gives -1, negative 1
 *)
const
  AVERROR_SIGN = (EINVAL shr 30) and $00000002 - 1;

(*
#if EDOM > 0
#define AVERROR(e) (-(e)) {**< Returns a negative error code from a POSIX error code, to return from library functions. *}
#define AVUNERROR(e) (-(e)) {**< Returns a POSIX error code from a library function error return value. *}
#else
{* Some platforms have E* and errno already negated. *}
#define AVERROR(e) (e)
#define AVUNERROR(e) (e)
#endif
*)

function AVERROR(err: integer): integer; // Note: see avutil.pas
function AVUNERROR(err: integer): integer; // Note: see avutil.pas

function FFERRTAG(a, b, c, d: AnsiChar): integer; inline;  // Note: see avutil.pas


const

  AVERROR_BSF_NOT_FOUND      = -(ord($F8) or (ord('B') shl 8) or (ord('S') shl 16) or (ord('F') shl 24)); ///< Bitstream filter not found
  AVERROR_BUG                = -(ord('B') or (ord('U') shl 8) or (ord('G') shl 16) or (ord('!') shl 24)); ///< Internal bug, also see AVERROR_BUG2
  AVERROR_BUFFER_TOO_SMALL   = -(ord('B') or (ord('U') shl 8) or (ord('F') shl 16) or (ord('S') shl 24)); ///< Buffer too small
  AVERROR_DECODER_NOT_FOUND  = -(ord($F8) or (ord('D') shl 8) or (ord('E') shl 16) or (ord('C') shl 24)); ///< Decoder not found
  AVERROR_DEMUXER_NOT_FOUND  = -(ord($F8) or (ord('D') shl 8) or (ord('E') shl 16) or (ord('M') shl 24)); ///< Demuxer not found
  AVERROR_ENCODER_NOT_FOUND  = -(ord($F8) or (ord('E') shl 8) or (ord('N') shl 16) or (ord('C') shl 24)); ///< Encoder not found
  AVERROR_EOF                = -(ord('E') or (ord('O') shl 8) or (ord('F') shl 16) or (ord(' ') shl 24)); ///< End of file
  AVERROR_EXIT               = -(ord('E') or (ord('X') shl 8) or (ord('I') shl 16) or (ord('T') shl 24)); ///< Immediate exit was requested; the called function should not be restarted
  AVERROR_EXTERNAL           = -(ord('E') or (ord('X') shl 8) or (ord('T') shl 16) or (ord(' ') shl 24)); ///< Generic error in an external library
  AVERROR_FILTER_NOT_FOUND   = -(ord($F8) or (ord('F') shl 8) or (ord('I') shl 16) or (ord('L') shl 24)); ///< Filter not found
  AVERROR_INVALIDDATA        = -(ord('I') or (ord('N') shl 8) or (ord('D') shl 16) or (ord('A') shl 24)); ///< Invalid data found when processing input
  AVERROR_MUXER_NOT_FOUND    = -(ord($F8) or (ord('M') shl 8) or (ord('U') shl 16) or (ord('X') shl 24)); ///< Muxer not found
  AVERROR_OPTION_NOT_FOUND   = -(ord($F8) or (ord('O') shl 8) or (ord('P') shl 16) or (ord('T') shl 24)); ///< Option not found
  AVERROR_PATCHWELCOME       = -(ord('P') or (ord('A') shl 8) or (ord('W') shl 16) or (ord('E') shl 24)); ///< Not yet implemented in FFmpeg, patches welcome
  AVERROR_PROTOCOL_NOT_FOUND = -(ord($F8) or (ord('P') shl 8) or (ord('R') shl 16) or (ord('O') shl 24)); ///< Protocol not found
  AVERROR_STREAM_NOT_FOUND   = -(ord($F8) or (ord('S') shl 8) or (ord('T') shl 16) or (ord('R') shl 24)); ///< Stream not found

(**
 * This is semantically identical to AVERROR_BUG
 * it has been introduced in Libav after our AVERROR_BUG and with a modified value.
 *)
  AVERROR_BUG2               = -(ord('B') or (ord('U') shl 8) or (ord('G') shl 16) or (ord(' ') shl 24));
  AVERROR_UNKNOWN            = -(ord('U') or (ord('N') shl 8) or (ord('K') shl 16) or (ord('N') shl 24)); ///< Unknown error, typically from an external library
  AVERROR_EXPERIMENTAL       = -($2bb2afa8);                                                              ///< Requested feature is flagged experimental. Set strict_std_compliance if you really want to use it.

  AV_ERROR_MAX_STRING_SIZE   = 64;


(*
 * Put a description of the AVERROR code errnum in errbuf.
 * In case of failure the global variable errno is set to indicate the
 * error. Even in case of failure av_strerror() will print a generic
 * error message indicating the errnum provided to errbuf.
 *
 * @param errnum      error code to describe
 * @param errbuf      buffer to which description is written
 * @param errbuf_size the size in bytes of errbuf
 * @return 0 on success, a negative value if a description for errnum
 * cannot be found
 *)
function av_strerror(errnum: integer; errbuf: PAnsiChar; errbuf_size: cardinal): integer;
  cdecl; external LIB_AVUTIL;

(**
 * Fill the provided buffer with a string containing an error string
 * corresponding to the AVERROR code errnum.
 *
 * @param errbuf         a buffer
 * @param errbuf_size    size in bytes of errbuf
 * @param errnum         error code to describe
 * @return the buffer in input, filled with the error description
 * @see av_strerror()
 *)
function av_make_error_string(errbuf: PAnsiChar; errbuf_size: cardinal; errnum: integer): PAnsiChar; inline; // Note: see avutil.pas


(**
 * Convenience macro, the return value should be used only directly in
 * function arguments but never stand-alone.
 *)
function av_err2str(errnum: integer): PAnsiChar; inline; // Note: see avutil.pas


(**
 * @}
 *)
