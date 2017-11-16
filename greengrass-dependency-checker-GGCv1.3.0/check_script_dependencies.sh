## Commands assumed to be present on the device:
## 1. echo
## 2. exit
## 3. set
##
## This script checks for shell or BusyBox variants of the following commands:
## 1. printf
## 2. uname
## 3. cat
## 4. ls
## 5. head
## 6. find
## 7. zcat
## 8. awk
## 9. sed
## 10. sysctl
## 11. wc
## 12. cut
## 13. sort
## 14. expr
## 15. grep
## 16. test
## 17. dirname
## 18. readlink
## 19. xargs
## 20. uniq
## 21. strings
## 22. id
##
## Shell commands not supported by Busybox and required to be present on the device:
## 1. eval
## 2. command
## 3. read
TEST_STRING="hello world\nHello World"
TEST_FILE="$0"
PATTERN="hello"

PRINTF="printf"
UNAME="uname"
CAT="cat"
LS="ls"
HEAD="head"
FIND="find"
ZCAT="zcat"
AWK="awk"
SED="sed"
SYSCTL="sysctl"
WC="wc"
CUT="cut"
SORT="sort"
EXPR="expr"
GREP="grep"
TEST="test"
DIRNAME="dirname"
READLINK="readlink"
TR="tr"
XARGS="xargs"
STRINGS="strings"
UNIQ="uniq"
ID="id"

DEPENDENCIES_PRESENT=1

check_printf_present() {
    {
        ## Try the shell command first
        printf "$TEST_STRING" 2>/dev/null 1>&2
    } || {
        {   ## Fall back to the BusyBox variant
            busybox printf "$TEST_STRING" 2>/dev/null 1>&2
        } && {
            PRINTF="busybox printf"
        }
    } || {
        wrap_bad "printf" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_eval_present() {
    {
        ## Busybox does not support 'eval'. Fail if 'eval' is not found.
        eval 2>/dev/null 1>&2
    } || {
        wrap_bad "eval" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_uname_present() {
    {
        uname 2>/dev/null 1>&2
    } || {
        {
            busybox uname 2>/dev/null 1>&2
        } && {
            UNAME="busybox uname"
        }
    } || {
        wrap_bad "uname" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_cat_present() {
    {
        cat "$TEST_FILE" 2>/dev/null 1>&2
    } || {
        {
            busybox cat "$TEST_FILE" 2>/dev/null 1>&2
        } && {
            CAT="busybox cat"
        }
    } || {
        wrap_bad "cat" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_ls_present() {
    {
        ls "$TEST_FILE"  2>/dev/null 1>&2
    } || {
        {
            busybox ls "$TEST_FILE"  2>/dev/null 1>&2
        } && {
            LS="busybox ls"
        }
    } || {
        wrap_bad "ls" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_head_present() {
    {
        $PRINTF "$TEST_STRING" | head -n 1  2>/dev/null 1>&2
    } || {
        {
            $PRINTF "$TEST_STRING" | busybox head -n 1  2>/dev/null 1>&2
        } && {
            HEAD="busybox head"
        }
    } || {
        wrap_bad "head" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_find_present() {
    {
        find . -maxdepth 1 2>/dev/null 1>&2
    } || {
        {
            busybox find . -maxdepth 1 2>/dev/null 1>&2
        } && {
            FIND="busybox find"
        }
    } || {
        wrap_bad "find" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_zcat_present() {
    {
        zcat --help  2>/dev/null 1>&2
    } || {
        {
            busybox zcat --help  2>/dev/null 1>&2
        } && {
            ZCAT="busybox zcat"
        }
    } || {
        wrap_bad "zcat" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_awk_present() {
    {
        awk {print} "$TEST_FILE"  2>/dev/null 1>&2
    } || {
        {
            busybox awk {print} "$TEST_FILE"  2>/dev/null 1>&2
        } && {
            AWK="busybox awk"
        }
    } || {
        wrap_bad "awk" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_sed_present() {
    {
        sed -n 1p "$TEST_FILE"  2>/dev/null 1>&2
    } || {
        {
            busybox sed -n 1p "$TEST_FILE"  2>/dev/null 1>&2
        } && {
            SED="busybox sed"
        }
    } || {
        wrap_bad "sed" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_sysctl_present() {
    {
        command -v sysctl 2>/dev/null 1>&2
    } || {
        {
            busybox sysctl --help 2>/dev/null 1>&2
        } && {
            SYSCTL="busybox sysctl"
        }
    } || {
        wrap_bad "sysctl" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_wc_present() {
    {
        wc "$TEST_FILE"  2>/dev/null 1>&2
    } || {
        {
            busybox wc "$TEST_FILE"  2>/dev/null 1>&2
        } && {
            WC="busybox wc"
        }
    } || {
        wrap_bad "wc" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_cut_present() {
    {
        $PRINTF "$TEST_STRING" | cut -d" " -f1  2>/dev/null 1>&2
    } || {
        {
            $PRINTF "$TEST_STRING" | busybox cut -d" " -f1  2>/dev/null 1>&2
        } && {
            CUT="busybox cut"
        }
    } || {
        wrap_bad "cut" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_sort_present() {
    {
        $PRINTF "$TEST_STRING" | sort  2>/dev/null 1>&2
    } || {
        {
            $PRINTF "$TEST_STRING" | busybox sort 2>/dev/null 1>&2
        } && {
            SORT="busybox sort"
        }
    } || {
        wrap_bad "sort" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_expr_present() {
    {
        expr linux : lin  2>/dev/null 1>&2
    } || {
        {
            busybox expr linux : lin 2>/dev/null 1>&2
        } && {
            EXPR="busybox expr"
        }
    } || {
        wrap_bad "expr" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_grep_present() {
    {
        echo "$TEST_STRING" | grep "$PATTERN" 2>/dev/null 1>&2
    } || {
        {
            echo "$TEST_STRING" | busybox grep "$PATTERN" 2>/dev/null 1>&2
        } && {
            GREP="busybox grep"
        }
    } || {
        wrap_bad "grep" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_test_present() {
    {
        test -n "$TEST_STRING" 2>/dev/null 1>&2
    } || {
        {
            busybox test -n "$TEST_STRING" 2>/dev/null 1>&2
        } && {
            TEST="busybox test"
        }
    } || {
        wrap_bad "test" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_dirname_present() {
    {
        dirname . 2>/dev/null 1>&2
    } || {
        {
            busybox dirname . 2>/dev/null 1>&2
        } && {
            DIRNAME="busybox dirname"
        }
    } || {
        wrap_bad "dirname" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_command_present() {
    {
        ## BusyBox does not support 'command'
        command 2>/dev/null 1>&2
    } || {
        wrap_bad "command" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_read_present() {
    {
        ## BusyBox does not support 'read'
        command -v read  2>/dev/null 1>&2
    } || {
        wrap_bad "read" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_readlink_present() {
    {
        command -v readlink 2>/dev/null 1>&2
    } || {
        {
            busybox readlink -f "$TEST_FILE"  2>/dev/null 1>&2
        } && {
            READLINK="busybox readlink"
        }
    } || {
        wrap_bad "readlink" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_tr_present() {
    {
        command -v tr 2>/dev/null 1>&2
    } || {
        {
            $PRINTF "$TEST_STRING" | busybox tr ";" " "  2>/dev/null 1>&2
        } && {
            TR="busybox tr"
        }
    } || {
        wrap_bad "tr" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_xargs_present() {
    {
        command -v xargs 2>/dev/null 1>&2
    } || {
        {
            $LS | busybox xargs echo  2>/dev/null 1>&2
        } && {
            XARGS="busybox xargs"
        }
    } || {
        wrap_bad "xargs" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_strings_present() {
    {
        command -v strings 2>/dev/null 1>&2
    } || {
        {
            busybox strings "$TEST_FILE"  2>/dev/null 1>&2
        } && {
            STRINGS="busybox strings"
        }
    } || {
        wrap_bad "strings" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_uniq_present() {
    {
        command -v uniq 2>/dev/null 1>&2
    } || {
        {
            $PRINTF "$TEST_STRING" | busybox uniq  2>/dev/null 1>&2
        } && {
            UNIQ="busybox uniq"
        }
    } || {
        wrap_bad "uniq" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_id_present() {
    {
        id 2>/dev/null 1>&2
    } || {
        {
            busybox id 2>/dev/null 1>&2
        } && {
            ID="busybox id"
        }
    } || {
        wrap_bad "id" "Not found"
        DEPENDENCIES_PRESENT=0
    }
}

check_commands_present() {
    check_printf_present
    check_eval_present
    check_uname_present
    check_cat_present
    check_ls_present
    check_head_present
    check_find_present
    check_zcat_present
    check_awk_present
    check_sed_present
    check_sysctl_present
    check_wc_present
    check_cut_present
    check_sort_present
    check_expr_present
    check_grep_present
    check_test_present
    check_dirname_present
    check_command_present
    check_read_present
    check_readlink_present
    check_tr_present
    check_xargs_present
    check_strings_present
    check_uniq_present
    check_id_present
}

check_root_user() {
    local effective_uid=$($ID | $GREP -o "uid=[0-9]*" | $CUT -d= -f2)

    if [ $effective_uid -ne 0 ]
    then
        fatal "The script needs to be run as root."
        fatal "Check the script usage with './check_ggc_dependencies --help'."
        exit 1;
    fi
}

check_script_dependencies() {
    echo "==========================Checking script dependencies=============================="
    check_commands_present
    if [ $DEPENDENCIES_PRESENT -eq 0 ]
    then
        fatal "The device is missing one or more of the script dependencies. Cannot proceed."
        exit 1;
    else
        success "The device has all commands required for the script to run.\n"
        check_root_user
        check_ggc_dependencies
    fi
}