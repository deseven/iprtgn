
ImportC "-lcurl"
  
  curl_easy_cleanup(handle.i)
  curl_easy_duphandle(handle.i) 
  curl_easy_getinfo(curl.i, info_type.i, info.i) 
  curl_easy_init()
  curl_init(url.s)
  curl_easy_perform(handle.i)
  curl_easy_reset(handle.i)
  curl_easy_setopt(handle.i, option.i, parameter.i)
  curl_easy_strerror(errornum.i) 
  curl_escape(url.i, length.i) 
  curl_formadd(firstitem.i, lastitem.i) 
  curl_formfree(form.i)
  curl_free(ptr.i) 
  curl_getdate(datestring.i, now.i) 
  curl_getenv(name.i) 
  curl_global_cleanup() 
  curl_global_init(flags.i) 
  curl_global_init_mem(flags.i, m.i, f.i, r.i, s.i, c.i) 
  curl_mprintf(format.i)
  curl_mfprintf(fd.i, format.i)
  curl_msprintf(buffer.i, format.i)
  curl_msnprintf(buffer.i, maxlength.i, format.i) 
  curl_mvprintf(format.i, args.i) 
  curl_mvfprintf(fd.i, format.i, args.i) 
  curl_mvsprintf(buffer.i, format.i, args.i) 
  curl_mvsnprintf(buffer.i, maxlength.i, format.i, args.i) 
  curl_maprintf(format.i)
  curl_mvaprintf(format.i, args.i) 
  curl_multi_add_handle(multi_handle.i, easy_handle.i) 
  curl_multi_cleanup(multi_handle.i) 
  curl_multi_fdset(multi_handle.i, read_fd_set.i, write_fd_set.i, exc_fd_set.i, max_fd.i) 
  curl_multi_info_read(multi_handle.i, msgs_in_queue.i) 
  curl_multi_init() 
  curl_multi_perform(multi_handle.i, running_handles.i) 
  curl_multi_remove_handle(multi_handle.i, easy_handle.i) 
  curl_multi_strerror(errornum.i) 
  curl_share_cleanup(share_handle.i) 
  curl_share_init() 
  curl_share_setopt(share.i, option.i, parameter.i) 
  curl_share_strerror(errornum.i) 
  curl_slist_append(slist.i, string.p-utf8) 
  curl_slist_free_all(slist.i) 
  curl_strequal(str1.i, str2.i) 
  curl_strnequal(str1.i, str2.i, len.i)
  curl_unescape(url.i, length.i) 
  curl_version() 
  curl_version_info(type.i) 
EndImport;}

Define ReceivedData.s

ProcedureC  RW_LibCurl_WriteFunction(*ptr, Size, NMemB, *Stream)
  ;retreives utf-8/ascii encoded data
  Protected SizeProper.i  = Size & 255
  Protected NMemBProper.i = NMemB
  Protected MyDataS.s
  Shared ReceivedData.s
  
  MyDataS = PeekS(*ptr, SizeProper * NMemBProper)
  ReceivedData + MyDataS
  ;Debug "> " + MyDataS
  ;Debug "# " + Str(Len(MyDataS))
  ;Debug "@ " + Str(Len(ReceivedData))
  ProcedureReturn SizeProper * NMemBProper
EndProcedure
Procedure.s RW_LibCurl_GetData()
  Shared ReceivedData.s
  Protected ReturnData.s
  
  ReturnData.s = ReceivedData.s
  ReceivedData.s = ""
  
  ProcedureReturn ReturnData.s
EndProcedure