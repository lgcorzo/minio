//go:build ignore
// +build ignore

// Copyright (c) 2015-2021 MinIO, Inc.
//
// This file is part of MinIO Object Storage stack
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

package main

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

func genLDFlags(version string) string {
	releaseTag, date := releaseTag(version)
	copyrightYear := strconv.Itoa(date.Year())
	cid := commitID()
	shortCid := cid
	if len(cid) >= 12 {
		shortCid = cid[:12]
	}
	ldflagsStr := "-s -w"
	ldflagsStr += " -X github.com/minio/minio/cmd.Version=" + version
	ldflagsStr += " -X github.com/minio/minio/cmd.CopyrightYear=" + copyrightYear
	ldflagsStr += " -X github.com/minio/minio/cmd.ReleaseTag=" + releaseTag
	ldflagsStr += " -X github.com/minio/minio/cmd.CommitID=" + cid
	ldflagsStr += " -X github.com/minio/minio/cmd.ShortCommitID=" + shortCid
	ldflagsStr += " -X github.com/minio/minio/cmd.GOPATH=" + os.Getenv("GOPATH")
	ldflagsStr += " -X github.com/minio/minio/cmd.GOROOT=" + os.Getenv("GOROOT")
	return ldflagsStr
}

// genReleaseTag prints release tag to the console for easy git tagging.
func releaseTag(version string) (string, time.Time) {
	relPrefix := "DEVELOPMENT"
	if prefix := os.Getenv("MINIO_RELEASE"); prefix != "" {
		relPrefix = prefix
	}

	relSuffix := ""
	if hotfix := os.Getenv("MINIO_HOTFIX"); hotfix != "" {
		relSuffix = hotfix
	}

	relTag := strings.Replace(version, " ", "-", -1)
	relTag = strings.Replace(relTag, ":", "-", -1)
	t, err := time.Parse("2006-01-02T15-04-05Z", relTag)
	if err != nil {
		panic(err)
	}
	relTag = strings.Replace(relTag, ",", "", -1)
	relTag = relPrefix + "." + relTag
	if relSuffix != "" {
		relTag += "." + relSuffix
	}

	return relTag, t
}

// commitID returns the abbreviated commit-id hash of the last commit.
func commitID() string {
	if commit := os.Getenv("MINIO_COMMIT_ID"); commit != "" {
		return commit
	}
	// git log --format="%H" -n1
	var (
		commit []byte
		err    error
	)
	cmdName := "git"
	cmdArgs := []string{"log", "--format=%H", "-n1"}
	if commit, err = exec.Command(cmdName, cmdArgs...).Output(); err != nil {
		return "unknown000000000000"
	}

	return strings.TrimSpace(string(commit))
}

func commitTime() time.Time {
	if ct := os.Getenv("MINIO_COMMIT_TIME"); ct != "" {
		if t, err := time.Parse(time.RFC3339, ct); err == nil {
			return t.UTC()
		}
	}
	// git log --format=%cD -n1
	var (
		commitUnix []byte
		err        error
	)
	cmdName := "git"
	cmdArgs := []string{"log", "--format=%cI", "-n1"}
	if commitUnix, err = exec.Command(cmdName, cmdArgs...).Output(); err != nil {
		return time.Now().UTC()
	}

	t, err := time.Parse(time.RFC3339, strings.TrimSpace(string(commitUnix)))
	if err != nil {
		return time.Now().UTC()
	}

	return t.UTC()
}

func main() {
	var version string
	if len(os.Args) > 1 {
		version = os.Args[1]
	} else {
		version = commitTime().Format(time.RFC3339)
	}

	fmt.Println(genLDFlags(version))
}
