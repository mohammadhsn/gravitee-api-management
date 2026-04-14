/*
 * Copyright (C) 2015 The Gravitee team (http://gravitee.io)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { Component, ElementRef, HostListener, OnInit } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

import { environment } from '../../../environments/environment';
import { LOCALE_STORAGE_KEY } from '../../services/translation.service';

interface LocaleOption {
  code: string;
  label: string;
}

const LOCALE_LABELS: Record<string, string> = {
  en: 'English',
  fr: 'Fran\u00e7ais',
  cs: '\u010ce\u0161tina',
  fa: '\u0641\u0627\u0631\u0633\u06CC',
};

@Component({
  selector: 'app-gv-language-switcher',
  templateUrl: './gv-language-switcher.component.html',
  styleUrls: ['./gv-language-switcher.component.css'],
  standalone: false,
})
export class GvLanguageSwitcherComponent implements OnInit {
  locales: LocaleOption[] = [];
  currentLang: string;
  isOpen = false;

  constructor(
    private translateService: TranslateService,
    private elementRef: ElementRef,
  ) {}

  @HostListener('document:click', ['$event.target'])
  onDocumentClick(target: HTMLElement) {
    if (this.isOpen && !this.elementRef.nativeElement.contains(target)) {
      this.isOpen = false;
    }
  }

  ngOnInit() {
    this.currentLang = this.translateService.currentLang || environment.locales[0];
    this.locales = environment.locales.map(code => ({
      code,
      label: LOCALE_LABELS[code] || code,
    }));
  }

  get currentLabel(): string {
    return LOCALE_LABELS[this.currentLang] || this.currentLang;
  }

  toggle() {
    this.isOpen = !this.isOpen;
  }

  close() {
    this.isOpen = false;
  }

  switchLanguage(locale: LocaleOption) {
    if (locale.code !== this.currentLang) {
      localStorage.setItem(LOCALE_STORAGE_KEY, locale.code);
      window.location.reload();
    }
    this.close();
  }
}
