/* REXX */
trace i
     parse arg path
     call syscalls 'ON'
     address syscall
     'aclinit acl'                       /* init variable ACL to hold acl  */
     'aclget acl (path)' acl_type_access /* get the file access acl        */
 say "acl.0="acl.0
     do i=1 by 1                         /* get each acl entry             */
        'aclgetentry acl acl.' i
 say "rc="rc "retval="retval "errno="errno
        if rc<0 | retval=-1 then leave   /* error, assume no more      */
        parse value '- - -' with pr pw px
        if acl.acl_read=1    then pr='R'    /* set rwx permissions         */
        if acl.acl_write=1   then pw='W'
        if acl.acl_execute=1 then px='X'
        aclid=acl.acl_id                 /* get uid or gid                 */
                                         /* determine acl type             */
        if acl.acl_entry_type=acl_entry_user then type='UID='
         else
          if acl.acl_entry_type=acl_entry_group then type='GID='
           else
            type='???='
        say pr || pw || px type || aclid   /* print line                   */
     end
     'aclfree acl'                       /* must free acl buffer           */

